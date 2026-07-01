"""
Router-level tests for POST /ml/verify — confirms photo_source is a truly
optional, fail-open field (never required, never a hard gate).
"""
from __future__ import annotations

from fastapi.testclient import TestClient

from ..main import app

client = TestClient(app)

_BASE_PAYLOAD = {
    "report_id": "r1",
    "lat": -12.121,
    "lng": -77.030,
    "type": "ROBBERY",
    "form_data": {"weapon": "knife", "injured": "no"},
    "user_reputation": 0.5,
    "has_evidence": True,
    "photo_age_minutes": 8.0,
}


def test_verify_without_photo_source_still_succeeds() -> None:
    """GIVEN a request with no photo_source WHEN posted THEN it succeeds (backward-compatible)."""
    response = client.post("/ml/verify", json=_BASE_PAYLOAD)
    assert response.status_code == 200
    body = response.json()
    assert 0.0 <= body["score"] <= 1.0
    assert isinstance(body["verified"], bool)


def test_verify_with_photo_source_exif_succeeds() -> None:
    response = client.post("/ml/verify", json={**_BASE_PAYLOAD, "photo_source": "exif"})
    assert response.status_code == 200


def test_verify_with_photo_source_device_clock_still_succeeds_never_gated() -> None:
    """GIVEN photo_source='device_clock' (untrusted) WHEN posted THEN it still returns 200 —
    untrusted provenance is informational only, it never blocks the response."""
    response = client.post("/ml/verify", json={**_BASE_PAYLOAD, "photo_source": "device_clock"})
    assert response.status_code == 200
    body = response.json()
    assert 0.0 <= body["score"] <= 1.0
