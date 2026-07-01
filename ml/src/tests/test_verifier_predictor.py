"""
Characterization tests for VerifierPredictor (ECOD + IsolationForest ensemble).

verifier_predictor.py had ZERO tests before this file (test_verifier.py only
covers the dead `ReportVerifier` stub in domain/report_verifier.py, which is
never wired into router.py). These tests LOCK the current v2 production
behavior BEFORE any retrain work — the strict-TDD safety net required to
touch previously-untested prod code. They target verifier_v2.joblib
explicitly (by absolute path), independent of settings.VERIFIER_MODEL_PATH,
so they stay a stable regression guard even after config.py points to v3.

v3-specific expectations (corrected enum, photo_trusted feature) live in the
TestV3* classes below, added once verifier_v3.joblib exists.
"""
from __future__ import annotations

from pathlib import Path

import pytest

from ..features.verification.infrastructure.verifier_predictor import VerifierPredictor

ML_ROOT = Path(__file__).resolve().parents[2]
V2_MODEL_PATH = str(ML_ROOT / "src" / "models" / "verifier_v2.joblib")
V3_MODEL_PATH = str(ML_ROOT / "src" / "models" / "verifier_v3.joblib")


@pytest.fixture(scope="module")
def v2_predictor() -> VerifierPredictor:
    predictor = VerifierPredictor(V2_MODEL_PATH)
    assert predictor.load() is True
    return predictor


class TestLoadV2:
    """GIVEN the real v2 bundle on disk WHEN load() runs THEN it succeeds."""

    def test_load_succeeds_with_real_artifact(self, v2_predictor: VerifierPredictor) -> None:
        assert v2_predictor.ready is True

    def test_load_fails_gracefully_with_bad_path(self) -> None:
        """GIVEN a non-existent path WHEN load() runs THEN it returns False (fail-open)."""
        predictor = VerifierPredictor("src/models/does-not-exist.joblib")
        assert predictor.load() is False
        assert predictor.ready is False


class TestDegradedModeV2:
    def test_verify_degraded_when_not_loaded(self) -> None:
        """GIVEN no bundle loaded WHEN verify() runs THEN it returns the neutral degraded result."""
        predictor = VerifierPredictor("src/models/does-not-exist.joblib")
        predictor.load()
        result = predictor.verify(
            lat=-12.121, lng=-77.030, incident_type="ROBBERY",
            weapon="knife", injured="no", hour=22, day_of_week=4, report_count=2,
        )
        assert result == {"is_coherent": True, "confidence": 0.5, "degraded": True}


class TestKnownSamplesV2:
    def test_known_normal_sample_is_coherent(self, v2_predictor: VerifierPredictor) -> None:
        """GIVEN a typical Miraflores robbery report WHEN verified THEN it is coherent."""
        result = v2_predictor.verify(
            lat=-12.121, lng=-77.030, incident_type="ROBBERY",
            weapon="knife", injured="no", hour=22, day_of_week=4, report_count=2,
            has_evidence=True, photo_age_minutes=8.0,
        )
        assert result["is_coherent"] is True
        assert result["degraded"] is False
        assert 0.0 <= result["confidence"] <= 1.0

    def test_known_anomaly_sample_is_incoherent(self, v2_predictor: VerifierPredictor) -> None:
        """GIVEN an extreme out-of-Lima firearm+injured report WHEN verified THEN ensemble AND flags it."""
        result = v2_predictor.verify(
            lat=-9.000, lng=-70.000, incident_type="VANDALISM",
            weapon="firearm", injured="yes", hour=13, day_of_week=2, report_count=1,
            has_evidence=False, photo_age_minutes=999.0,
        )
        assert result["is_coherent"] is False
        assert result["degraded"] is False


class TestBuildFeaturesV2:
    def test_photo_age_none_defaults_to_sentinel(self, v2_predictor: VerifierPredictor) -> None:
        """GIVEN photo_age_minutes=None WHEN features are built THEN it clips to the 999 sentinel."""
        x = v2_predictor._build_features(
            lat=-12.1, lng=-77.0, incident_type="ROBBERY", weapon="none", injured="no",
            hour=10, day_of_week=1, report_count=1, has_evidence=False, photo_age_minutes=None,
        )
        feature_columns = v2_predictor._bundle["feature_columns"]  # type: ignore[index]
        idx = feature_columns.index("photo_age_minutes")
        assert x[0][idx] == 999.0

    def test_has_evidence_false_defaults_to_zero(self, v2_predictor: VerifierPredictor) -> None:
        """GIVEN has_evidence=False WHEN features are built THEN has_evidence feature is 0.0."""
        x = v2_predictor._build_features(
            lat=-12.1, lng=-77.0, incident_type="ROBBERY", weapon="none", injured="no",
            hour=10, day_of_week=1, report_count=1, has_evidence=False, photo_age_minutes=None,
        )
        feature_columns = v2_predictor._bundle["feature_columns"]  # type: ignore[index]
        idx = feature_columns.index("has_evidence")
        assert x[0][idx] == 0.0


class TestUnknownIncidentTypeV2:
    def test_unknown_type_does_not_crash(self, v2_predictor: VerifierPredictor) -> None:
        """GIVEN an incident_type outside the trained enum WHEN verified THEN OHE ignores it, no crash."""
        result = v2_predictor.verify(
            lat=-12.1, lng=-77.0, incident_type="NOT_A_REAL_TYPE",
            weapon="none", injured="no", hour=10, day_of_week=1, report_count=1,
        )
        assert result["degraded"] is False
        assert isinstance(result["is_coherent"], bool)
        assert 0.0 <= result["confidence"] <= 1.0


# ──────────────────────────────────────────────────────────────────────────────
# v3 — corrected enum + photo_trusted (informational, never a hard gate)
# ──────────────────────────────────────────────────────────────────────────────

REAL_INCIDENT_TYPES = ["ROBBERY", "ACCIDENT", "HARASSMENT", "EXTORTION", "SUSPICIOUS"]


@pytest.fixture(scope="module")
def v3_predictor() -> VerifierPredictor:
    predictor = VerifierPredictor(V3_MODEL_PATH)
    assert predictor.load() is True
    return predictor


class TestV3RealEnum:
    @pytest.mark.parametrize("incident_type", REAL_INCIDENT_TYPES)
    def test_real_enum_type_produces_nonzero_one_hot(
        self, v3_predictor: VerifierPredictor, incident_type: str
    ) -> None:
        """GIVEN each real Prisma IncidentType WHEN features are built THEN its one-hot column fires.

        This is the bug being fixed — under the old wrong enum, ACCIDENT/HARASSMENT/
        EXTORTION always produced an all-zero one-hot vector (OHE handle_unknown='ignore').
        """
        x = v3_predictor._build_features(
            lat=-12.1, lng=-77.0, incident_type=incident_type, weapon="none", injured="no",
            hour=10, day_of_week=1, report_count=1,
        )
        feature_columns = v3_predictor._bundle["feature_columns"]  # type: ignore[index]
        idx = feature_columns.index(f"type_{incident_type}")
        assert x[0][idx] == 1.0


class TestV3PhotoTrusted:
    def test_photo_trusted_in_feature_columns(self, v3_predictor: VerifierPredictor) -> None:
        assert "photo_trusted" in v3_predictor._bundle["feature_columns"]  # type: ignore[index]

    def test_exif_source_sets_trusted_flag(self, v3_predictor: VerifierPredictor) -> None:
        x = v3_predictor._build_features(
            lat=-12.1, lng=-77.0, incident_type="ROBBERY", weapon="none", injured="no",
            hour=10, day_of_week=1, report_count=1, photo_source="exif",
        )
        idx = v3_predictor._bundle["feature_columns"].index("photo_trusted")  # type: ignore[index]
        assert x[0][idx] == 1.0

    def test_device_clock_source_sets_untrusted_flag(self, v3_predictor: VerifierPredictor) -> None:
        x = v3_predictor._build_features(
            lat=-12.1, lng=-77.0, incident_type="ROBBERY", weapon="none", injured="no",
            hour=10, day_of_week=1, report_count=1, photo_source="device_clock",
        )
        idx = v3_predictor._bundle["feature_columns"].index("photo_trusted")  # type: ignore[index]
        assert x[0][idx] == 0.0

    def test_missing_photo_source_defaults_to_untrusted_no_crash(
        self, v3_predictor: VerifierPredictor
    ) -> None:
        """GIVEN no photo_source at all WHEN verified THEN it defaults safely, no crash."""
        result = v3_predictor.verify(
            lat=-12.1, lng=-77.0, incident_type="SUSPICIOUS", weapon="none", injured="no",
            hour=10, day_of_week=1, report_count=1,
        )
        assert result["degraded"] is False
        assert 0.0 <= result["confidence"] <= 1.0

    def test_photo_trusted_is_informational_not_a_hard_gate(
        self, v3_predictor: VerifierPredictor
    ) -> None:
        """GIVEN a clearly-coherent report WHEN photo_source flips exif -> device_clock -> absent
        THEN is_coherent stays the SAME (untrusted provenance never by itself flips a coherent
        report to a hard reject). photo_trusted is one ensemble feature, not a gate — a
        client-asserted photo_source must not deterministically block a report (discovery #884).

        NOTE: deterministic assertion — v3 is a fixed committed bundle, so this exact input's
        outcome is stable (not flaky). It proves the non-gate property: device_clock/absent
        provenance does NOT force is_coherent=False on an otherwise-coherent report."""
        common = dict(
            lat=-12.121, lng=-77.030, incident_type="ROBBERY", weapon="knife", injured="no",
            hour=22, day_of_week=4, report_count=2, has_evidence=True, photo_age_minutes=8.0,
        )
        trusted = v3_predictor.verify(**common, photo_source="exif")
        untrusted = v3_predictor.verify(**common, photo_source="device_clock")
        absent = v3_predictor.verify(**common)  # no photo_source

        # Baseline: this report IS coherent — so it's a valid witness for the non-gate property.
        assert trusted["is_coherent"] is True
        # The core invariant: untrusted / absent provenance does NOT flip a coherent report to rejected.
        assert untrusted["is_coherent"] == trusted["is_coherent"]
        assert absent["is_coherent"] == trusted["is_coherent"]
        assert untrusted["degraded"] is False and absent["degraded"] is False


class TestV3UnknownIncidentType:
    def test_unknown_type_does_not_crash(self, v3_predictor: VerifierPredictor) -> None:
        result = v3_predictor.verify(
            lat=-12.1, lng=-77.0, incident_type="NOT_A_REAL_TYPE",
            weapon="none", injured="no", hour=10, day_of_week=1, report_count=1,
        )
        assert result["degraded"] is False
        assert isinstance(result["is_coherent"], bool)
        assert 0.0 <= result["confidence"] <= 1.0


class TestV2BackwardCompatibility:
    def test_v2_still_loads_and_verifies_without_photo_source(
        self, v2_predictor: VerifierPredictor
    ) -> None:
        """GIVEN the v2 bundle (no photo_trusted column) WHEN verify() runs without
        photo_source THEN it still works — the new kwarg is additive/optional and
        v2's feature_columns selection silently drops photo_trusted from the row dict."""
        result = v2_predictor.verify(
            lat=-12.121, lng=-77.030, incident_type="ROBBERY",
            weapon="knife", injured="no", hour=22, day_of_week=4, report_count=2,
            has_evidence=True, photo_age_minutes=8.0,
        )
        assert result["degraded"] is False
        assert 0.0 <= result["confidence"] <= 1.0
