import pytest
from ..features.verification.domain.report_verifier import (
    ReportVerifier,
    VerifyReportRequest,
)


@pytest.fixture
def verifier() -> ReportVerifier:
    return ReportVerifier()


@pytest.mark.asyncio
async def test_verify_returns_coherent_by_default(verifier: ReportVerifier) -> None:
    """GIVEN un reporte normal WHEN se verifica THEN retorna coherente."""
    request = VerifyReportRequest(
        incident_type="ROBBERY",
        lat=-12.05,
        lng=-77.04,
        hour=22,
        form_data={"weapon": "none", "stillInArea": "fled_foot"},
        report_count=2,
    )
    response = await verifier.verify(request)
    assert response.is_coherent is True
    assert 0.0 <= response.confidence <= 1.0
    assert response.suggested_severity in ("LOW", "MODERATE", "CRITICAL")
    assert response.processing_time_ms >= 0


@pytest.mark.asyncio
async def test_verify_suggests_critical_for_firearm(verifier: ReportVerifier) -> None:
    """GIVEN reporte con arma de fuego WHEN se verifica THEN sugiere CRITICAL."""
    request = VerifyReportRequest(
        incident_type="ROBBERY",
        lat=-12.05,
        lng=-77.04,
        hour=23,
        form_data={"weapon": "firearm", "stillInArea": "yes"},
        report_count=1,
    )
    response = await verifier.verify(request)
    assert response.suggested_severity == "CRITICAL"
