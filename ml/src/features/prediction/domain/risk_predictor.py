"""
RiskPredictor — sirve el modelo XGBoost Poisson entrenado (predictor_v1.joblib).

Predice un CONTEO esperado de incidentes (λ) por zona × hora × día de semana y lo
escala a un risk_score 0-100. Las lag features (memoria temporal) se toman de la
tabla de serving del bundle: el nivel típico de actividad reciente de cada zona a
cada hora. En producción se reemplazan por lags reales (incidentes recientes vía
BD/Redis) sin cambiar el modelo.

Fail-open: sin modelo cargado retorna un score neutro y degraded=True — nunca
lanza, para no tumbar el microservicio.
"""
from __future__ import annotations

from typing import Any, Optional

from pydantic import BaseModel


class PredictRiskRequest(BaseModel):
    """Solicitud de predicción de riesgo por ubicación y momento."""
    lat: float
    lng: float
    hour: int          # 0-23
    day_of_week: int   # 0=lunes ... 6=domingo


class PredictRiskResponse(BaseModel):
    """Respuesta de predicción."""
    risk_score: int          # 0-100
    predicted_hour: int
    day_of_week: int
    expected_count: float    # λ del modelo Poisson (conteo esperado)
    confidence: float        # 0.0-1.0 (proxy: λ/cap)
    degraded: bool           # True si el modelo no está cargado
    processing_time_ms: float


class RiskPredictor:
    """Envuelve el bundle XGBoost y expone predict()."""

    def __init__(self, model_path: Optional[str] = None) -> None:
        self._bundle: Optional[dict[str, Any]] = None
        self._model_path = model_path

    def load_model(self) -> bool:
        """Carga el bundle. Devuelve False si no existe/no es del tipo esperado."""
        import joblib

        if not self._model_path:
            return False
        try:
            bundle = joblib.load(self._model_path)
        except Exception:  # noqa: BLE001 — sin modelo el servicio sigue (fail-open)
            self._bundle = None
            return False
        # El bundle espacial legacy (v1-spatial) no tiene 'model' — no sirve para predecir.
        if not isinstance(bundle, dict) or "model" not in bundle:
            self._bundle = None
            return False
        self._bundle = bundle
        return True

    @property
    def ready(self) -> bool:
        return self._bundle is not None

    def _zone_id(self, lat: float, lng: float) -> str:
        """Discretiza (lat,lng) al mismo tile que usó el entrenamiento."""
        b = self._bundle
        assert b is not None
        gi = int((lat - b["lat_min"]) // b["tile"])
        gj = int((lng - b["lng_min"]) // b["tile"])
        return f"{gi}_{gj}"

    def _serving_lags(self, zone_id: str, hour: int) -> dict[str, float]:
        """Lags típicos de la zona a esa hora. Fallback a 0 (cold start / zona sin historia)."""
        b = self._bundle
        assert b is not None
        zone = b["serving_lags"].get(zone_id, {})
        lags = zone.get(hour)
        if lags is not None:
            return lags
        return {c: 0.0 for c in b["lag_cols"]}

    async def predict(self, request: PredictRiskRequest) -> PredictRiskResponse:
        import time

        import numpy as np
        import pandas as pd

        start = time.time()

        if not self.ready:
            return PredictRiskResponse(
                risk_score=0, predicted_hour=request.hour, day_of_week=request.day_of_week,
                expected_count=0.0, confidence=0.0, degraded=True,
                processing_time_ms=(time.time() - start) * 1000,
            )

        b = self._bundle
        assert b is not None
        zone_id = self._zone_id(request.lat, request.lng)
        code = b["zone_to_code"].get(zone_id, -1)  # zona desconocida → -1 (XGBoost lo tolera)
        zlat, zlng = b["zone_centers"].get(zone_id, (request.lat, request.lng))
        lags = self._serving_lags(zone_id, request.hour)

        h, dow = request.hour, request.day_of_week
        row = pd.DataFrame([{
            "zone_code": code, "zone_lat": zlat, "zone_lng": zlng,
            "hour_sin": np.sin(2 * np.pi * h / 24), "hour_cos": np.cos(2 * np.pi * h / 24),
            "dow_sin": np.sin(2 * np.pi * dow / 7), "dow_cos": np.cos(2 * np.pi * dow / 7),
            "is_weekend": int(dow >= 5),
            **lags,
        }])[b["features"]]

        lmbda = float(np.clip(b["model"].predict(row)[0], 0, None))
        cap = b["lambda_cap"]
        risk_score = int(np.clip(round(100 * lmbda / cap), 0, 100))
        confidence = round(float(min(1.0, lmbda / cap)), 3)

        return PredictRiskResponse(
            risk_score=risk_score, predicted_hour=h, day_of_week=dow,
            expected_count=round(lmbda, 3), confidence=confidence, degraded=False,
            processing_time_ms=(time.time() - start) * 1000,
        )
