from typing import Optional
from pydantic import BaseModel


class VerifyReportRequest(BaseModel):
    """Solicitud de verificación de coherencia de un reporte."""
    incident_type: str
    lat: float
    lng: float
    hour: int  # 0–23
    form_data: dict[str, str]
    report_count: int


class VerifyReportResponse(BaseModel):
    """Respuesta de verificación."""
    is_coherent: bool
    confidence: float          # 0.0 – 1.0
    suggested_severity: str    # "LOW" | "MODERATE" | "CRITICAL"
    processing_time_ms: float


class ReportVerifier:
    """
    Verifica coherencia de reportes usando Isolation Forest.
    Detecta outliers (reportes falsos/incoherentes) antes de alimentar el threshold engine.
    """

    def __init__(self, model_path: Optional[str] = None) -> None:
        self._model = None
        self._model_path = model_path

    def load_model(self) -> None:
        """Carga el modelo entrenado desde disco."""
        import joblib
        if self._model_path:
            self._model = joblib.load(self._model_path)

    async def verify(self, request: VerifyReportRequest) -> VerifyReportResponse:
        """
        Verifica si un reporte es coherente con el contexto histórico.
        Si el modelo no está cargado, retorna coherente por defecto (modo dev).
        """
        import time
        start = time.time()

        # TODO(ml): implementar predicción real con Isolation Forest
        # Por ahora retorna coherente por defecto para no bloquear el MVP
        is_coherent = True
        confidence = 0.85

        # Severidad sugerida basada en formulario
        suggested_severity = self._suggest_severity(request)

        processing_time_ms = (time.time() - start) * 1000

        return VerifyReportResponse(
            is_coherent=is_coherent,
            confidence=confidence,
            suggested_severity=suggested_severity,
            processing_time_ms=processing_time_ms,
        )

    def _suggest_severity(self, request: VerifyReportRequest) -> str:
        """Sugiere severidad basada en respuestas del formulario."""
        form = request.form_data

        # Escalada por formulario — CONSTRAINTS.md
        if form.get("weapon") == "firearm" or form.get("injured") == "yes":
            return "CRITICAL"
        if request.report_count >= 3:
            return "MODERATE"
        return "LOW"
