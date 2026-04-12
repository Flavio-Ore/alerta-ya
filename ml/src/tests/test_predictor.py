import pytest
from ..features.prediction.domain.risk_predictor import (
    RiskPredictor,
    PredictRiskRequest,
)


@pytest.fixture
def predictor() -> RiskPredictor:
    return RiskPredictor()


@pytest.mark.asyncio
async def test_predict_returns_valid_risk_score(predictor: RiskPredictor) -> None:
    """GIVEN una zona y hora WHEN se predice THEN retorna score 0–100."""
    request = PredictRiskRequest(
        district="Miraflores",
        lat=-12.12,
        lng=-77.03,
        hour=22,
        day_of_week=4,
    )
    response = await predictor.predict(request)
    assert 0 <= response.risk_score <= 100
    assert 0.0 <= response.confidence <= 1.0
    assert response.district == "Miraflores"
