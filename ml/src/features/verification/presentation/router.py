"""
Router de verificación de reportes — POST /ml/verify

Contrato alineado con el cliente del API (api/src/.../ml.client.ts):
  entrada: report_id, lat, lng, type, form_data, user_reputation
  salida:  score (0–1), verified (bool)

NUNCA recibe userId — solo datos del incidente y reputación (anonimato del reportante).
"""
from __future__ import annotations

from datetime import datetime
from typing import Any

from fastapi import APIRouter
from pydantic import BaseModel, Field

from ....core.config import settings
from ..infrastructure.verifier_predictor import VerifierPredictor

router = APIRouter()

# Modelo cargado una vez al importar (cache en memoria del proceso)
_predictor = VerifierPredictor(settings.VERIFIER_MODEL_PATH)
_predictor.load()


class VerifyRequest(BaseModel):
    report_id:       str
    lat:             float
    lng:             float
    type:            str
    form_data:       dict[str, Any] = Field(default_factory=dict)
    user_reputation: float = 0.5


class VerifyResponse(BaseModel):
    score:    float  # 0–1: confianza en que el reporte es coherente
    verified: bool   # True si pasa el verificador (no es anomalía)


@router.post("/verify", response_model=VerifyResponse)
async def verify(req: VerifyRequest) -> VerifyResponse:
    # hour/day_of_week se toman del momento del reporte (el dato no viene en el payload)
    now = datetime.now()
    result = _predictor.verify(
        lat=req.lat,
        lng=req.lng,
        incident_type=req.type,
        weapon=str(req.form_data.get("weapon", "none")),
        injured=str(req.form_data.get("injured", "no")),
        hour=now.hour,
        day_of_week=now.weekday(),
        report_count=int(req.form_data.get("report_count", 1)),
    )
    return VerifyResponse(score=float(result["confidence"]), verified=bool(result["is_coherent"]))
