"""Tests del monitor de drift (PSI)."""

import numpy as np
import pandas as pd

from ..features.monitoring.drift import (
    DRIFT_THRESHOLD,
    compute_drift,
    population_stability_index,
)


def _rng() -> np.random.Generator:
    return np.random.default_rng(42)


def test_psi_is_near_zero_for_identical_distributions() -> None:
    rng = _rng()
    sample = rng.normal(0, 1, size=5000)
    psi = population_stability_index(sample, sample)
    assert psi < 0.01


def test_psi_is_high_for_shifted_distribution() -> None:
    rng = _rng()
    baseline = rng.normal(0, 1, size=5000)
    shifted = rng.normal(3, 1, size=5000)  # media corrida 3 sigmas
    psi = population_stability_index(baseline, shifted)
    assert psi >= DRIFT_THRESHOLD


def test_psi_handles_constant_feature_without_crashing() -> None:
    baseline = np.full(100, 7.0)
    current = np.full(100, 7.0)
    assert population_stability_index(baseline, current) == 0.0


def test_psi_handles_empty_input() -> None:
    assert population_stability_index(np.array([]), np.array([1.0, 2.0])) == 0.0


def test_compute_drift_flags_only_the_drifted_feature() -> None:
    rng = _rng()
    baseline = pd.DataFrame(
        {"stable": rng.normal(0, 1, 5000), "moving": rng.normal(0, 1, 5000)}
    )
    current = pd.DataFrame(
        {"stable": rng.normal(0, 1, 5000), "moving": rng.normal(4, 1, 5000)}
    )
    report = compute_drift(baseline, current, ["stable", "moving"])

    assert report["drift_detected"] is True
    assert report["features"]["moving"]["drifted"] is True
    assert report["features"]["stable"]["drifted"] is False
    assert report["threshold"] == DRIFT_THRESHOLD
