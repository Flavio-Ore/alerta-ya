import pytest

from ..core.config import settings
from ..features.prediction.domain.risk_predictor import (
    PredictRiskRequest,
    RiskPredictor,
)


@pytest.fixture
def loaded_predictor() -> RiskPredictor:
    p = RiskPredictor(settings.PREDICTOR_MODEL_PATH)
    p.load_model()
    return p


@pytest.mark.asyncio
async def test_predict_returns_valid_risk_score(loaded_predictor: RiskPredictor) -> None:
    """GIVEN una zona y hora WHEN se predice THEN retorna score 0-100 acotado."""
    if not loaded_predictor.ready:
        pytest.skip("predictor_v1.joblib no entrenado — correr scripts/train_predictor.py")
    r = await loaded_predictor.predict(
        PredictRiskRequest(lat=-12.12, lng=-77.03, hour=22, day_of_week=4)
    )
    assert 0 <= r.risk_score <= 100
    assert 0.0 <= r.confidence <= 1.0
    assert r.expected_count >= 0.0
    assert r.degraded is False


@pytest.mark.asyncio
async def test_fail_open_without_model() -> None:
    """Sin modelo cargado NO lanza: score neutro y degraded=True."""
    p = RiskPredictor(model_path="/nonexistent/model.joblib")
    assert p.load_model() is False
    r = await p.predict(PredictRiskRequest(lat=-12.12, lng=-77.03, hour=22, day_of_week=4))
    assert r.degraded is True
    assert r.risk_score == 0


@pytest.mark.asyncio
async def test_learned_signal_night_weekend_higher_than_weekday_morning(
    loaded_predictor: RiskPredictor,
) -> None:
    """El modelo aprendió el sesgo: en un hotspot, sábado noche > martes mañana."""
    if not loaded_predictor.ready:
        pytest.skip("predictor_v1.joblib no entrenado")
    hotspot = {"lat": -12.066, "lng": -77.030}  # La Victoria (mayor peso en el seed)
    sat_night = await loaded_predictor.predict(
        PredictRiskRequest(**hotspot, hour=23, day_of_week=5)
    )
    tue_morning = await loaded_predictor.predict(
        PredictRiskRequest(**hotspot, hour=7, day_of_week=1)
    )
    assert sat_night.risk_score > tue_morning.risk_score
