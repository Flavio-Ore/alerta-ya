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


# TODO(features): montar routers de verificación y predicción
# from .features.verification.presentation.router import router as verification_router
# from .features.prediction.presentation.router import router as prediction_router
# app.include_router(verification_router, prefix="/verify", tags=["verification"])
# app.include_router(prediction_router, prefix="/predict", tags=["prediction"])
