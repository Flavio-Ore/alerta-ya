"""
Router de predicción de riesgo — POST /predict

Sirve el modelo XGBoost Poisson (predictor_v1.joblib). Predice el conteo esperado
de incidentes por zona × hora × día de semana y lo escala a risk_score 0-100.

NUNCA recibe datos del reportante — solo ubicación y momento (sin PII).
"""
from __future__ import annotations

from fastapi import APIRouter

from ....core.config import settings
from ..domain.risk_predictor import PredictRiskRequest, PredictRiskResponse, RiskPredictor

router = APIRouter()

# Modelo cargado una vez al importar (cache en memoria del proceso).
_predictor = RiskPredictor(settings.PREDICTOR_MODEL_PATH)
_predictor.load_model()


@router.post("/risk", response_model=PredictRiskResponse)
async def predict_risk(req: PredictRiskRequest) -> PredictRiskResponse:
    return await _predictor.predict(req)


@router.get("/health")
async def predict_health() -> dict:
    """Estado del modelo de predicción (útil para verificar el deploy)."""
    return {"model_loaded": _predictor.ready}
