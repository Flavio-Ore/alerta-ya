from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .core.config import settings

app = FastAPI(
    title="AlertaYa ML Service",
    description="Microservicio de verificación y predicción de incidentes — Lima, Perú",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=[settings.API_URL],
    allow_credentials=True,
    allow_methods=["GET", "POST"],
    allow_headers=["*"],
)


@app.get("/health")
async def health_check() -> dict:
    """Health check endpoint."""
    return {
        "status": "ok",
        "service": "alertaya-ml",
    }


from .features.verification.presentation.router import router as verification_router

# /ml/verify — verificación de coherencia de reportes (ECOD + Isolation Forest)
app.include_router(verification_router, prefix="/ml", tags=["verification"])

from .features.prediction.presentation.router import router as prediction_router

# /predict/risk — predicción de riesgo (XGBoost Poisson, conteo esperado → 0-100)
app.include_router(prediction_router, prefix="/predict", tags=["prediction"])
