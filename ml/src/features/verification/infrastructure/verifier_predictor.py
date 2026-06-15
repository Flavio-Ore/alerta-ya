"""
Carga el modelo verifier_v1.joblib (ECOD + Isolation Forest) y verifica reportes.

El bundle (generado por notebooks/01_verifier_training.ipynb) contiene:
  ecod, iforest, ohe, feature_columns, incident_types, flag_maps.

Detección de anomalías por ensemble AND: un reporte se marca incoherente solo si
ECOD Y IsolationForest coinciden → minimiza falsos positivos (no marcar reportes legítimos).
"""
from __future__ import annotations

from typing import Any, Optional

import joblib
import numpy as np
import pandas as pd


class VerifierPredictor:
    """Envuelve el bundle entrenado y expone verify()."""

    def __init__(self, model_path: str) -> None:
        self._path = model_path
        self._bundle: Optional[dict[str, Any]] = None

    def load(self) -> bool:
        """Carga el bundle desde disco. Devuelve False si no existe (modo degradado)."""
        try:
            self._bundle = joblib.load(self._path)
            return True
        except Exception:  # noqa: BLE001 — sin modelo el servicio sigue (fail-open)
            self._bundle = None
            return False

    @property
    def ready(self) -> bool:
        return self._bundle is not None

    def _build_features(
        self,
        lat: float,
        lng: float,
        incident_type: str,
        weapon: str,
        injured: str,
        hour: int,
        day_of_week: int,
        report_count: int,
    ) -> np.ndarray:
        b = self._bundle
        assert b is not None
        flags = b["flag_maps"]

        row: dict[str, float] = {
            "lat":         lat,
            "lng":         lng,
            "hour_sin":    np.sin(2 * np.pi * hour / 24),
            "hour_cos":    np.cos(2 * np.pi * hour / 24),
            "dow_sin":     np.sin(2 * np.pi * day_of_week / 7),
            "dow_cos":     np.cos(2 * np.pi * day_of_week / 7),
            "weapon_lvl":  flags["weapon"].get(weapon, 0),
            "injured_lvl": flags["injured"].get(injured, 0),
            "report_count": report_count,
        }
        # One-hot del tipo de incidente (handle_unknown='ignore' → tipo desconocido = todo 0)
        type_arr = b["ohe"].transform(pd.DataFrame([{"incident_type": incident_type}]))
        for col, val in zip([f"type_{t}" for t in b["incident_types"]], type_arr[0]):
            row[col] = val

        return pd.DataFrame([row])[b["feature_columns"]].values

    def verify(
        self,
        *,
        lat: float,
        lng: float,
        incident_type: str,
        weapon: str = "none",
        injured: str = "no",
        hour: int,
        day_of_week: int,
        report_count: int = 1,
    ) -> dict[str, Any]:
        """Devuelve {is_coherent, confidence, degraded}. Sin modelo → coherente neutro."""
        if not self.ready:
            return {"is_coherent": True, "confidence": 0.5, "degraded": True}

        b = self._bundle
        assert b is not None
        x = self._build_features(lat, lng, incident_type, weapon, injured, hour, day_of_week, report_count)

        ecod_anomaly = bool(b["ecod"].predict(x)[0] == 1)        # PyOD: 1 = outlier
        if_anomaly = bool(b["iforest"].predict(x)[0] == -1)      # sklearn: -1 = outlier
        is_anomaly = ecod_anomaly and if_anomaly                 # ensemble AND

        p_out = float(b["ecod"].predict_proba(x)[0, 1])
        confidence = p_out if is_anomaly else 1.0 - p_out
        return {"is_coherent": not is_anomaly, "confidence": round(confidence, 3), "degraded": False}
