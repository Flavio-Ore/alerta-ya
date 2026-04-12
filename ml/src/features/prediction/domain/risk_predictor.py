from typing import Optional
from pydantic import BaseModel


class PredictRiskRequest(BaseModel):
    """Solicitud de predicción de riesgo por zona y hora."""
    district: str
    lat: float
    lng: float
    hour: int   # 0–23
    day_of_week: int  # 0=lunes, 6=domingo


class PredictRiskResponse(BaseModel):
    """Respuesta de predicción."""
    district: str
    risk_score: int        # 0–100
    predicted_hour: int
    confidence: float      # 0.0 – 1.0
    processing_time_ms: float


class RiskPredictor:
    """
    Predice zonas de riesgo usando Random Forest + Prophet.
    El resultado se cachea en la tabla risk_zones de PostgreSQL.
    """

    def __init__(self, model_path: Optional[str] = None) -> None:
        self._model = None
        self._model_path = model_path

    def load_model(self) -> None:
        """Carga el modelo entrenado desde disco."""
        import joblib
        if self._model_path:
            self._model = joblib.load(self._model_path)

    async def predict(self, request: PredictRiskRequest) -> PredictRiskResponse:
        """
        Predice el nivel de riesgo para una zona y hora específica.
        """
        import time
        start = time.time()

        # TODO(ml): implementar predicción real con Random Forest + Prophet
        risk_score = 50  # Placeholder
        confidence = 0.70

        processing_time_ms = (time.time() - start) * 1000

        return PredictRiskResponse(
            district=request.district,
            risk_score=risk_score,
            predicted_hour=request.hour,
            confidence=confidence,
            processing_time_ms=processing_time_ms,
        )
