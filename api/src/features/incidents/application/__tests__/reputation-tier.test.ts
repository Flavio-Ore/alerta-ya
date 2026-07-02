import { describe, it, expect } from 'vitest';

import {
  reputationTier,
  aggregateReporterTier,
  ownerReputationLevel,
  TIER_THRESHOLDS,
} from '../reputation-tier';

describe('reputationTier', () => {
  it('returns high at/above the HIGH threshold', () => {
    expect(reputationTier(TIER_THRESHOLDS.HIGH)).toBe('high');
    expect(reputationTier(200)).toBe('high');
  });

  it('returns low strictly below the LOW threshold', () => {
    expect(reputationTier(TIER_THRESHOLDS.LOW - 1)).toBe('low');
    expect(reputationTier(0)).toBe('low');
  });

  it('returns medium for the default score and the mid band', () => {
    expect(reputationTier(100)).toBe('medium'); // default
    expect(reputationTier(TIER_THRESHOLDS.LOW)).toBe('medium'); // boundary inclusive
    expect(reputationTier(TIER_THRESHOLDS.HIGH - 1)).toBe('medium');
  });
});

describe('aggregateReporterTier', () => {
  it('returns null when there are no reporters', () => {
    expect(aggregateReporterTier([])).toBeNull();
  });

  it('uses the average, so one high score does not dominate a group', () => {
    // avg([200, 80, 80]) = 120 -> high, but avg([200, 80, 80, 80]) = 110 -> medium
    expect(aggregateReporterTier([200, 80, 80])).toBe('high');
    expect(aggregateReporterTier([200, 80, 80, 80])).toBe('medium');
  });

  it('single reporter mirrors its own tier', () => {
    expect(aggregateReporterTier([100])).toBe('medium');
    expect(aggregateReporterTier([50])).toBe('low');
  });
});

describe('ownerReputationLevel', () => {
  it('exposes the exact score to the owner (unlike the public tier)', () => {
    expect(ownerReputationLevel(103).score).toBe(103);
  });

  it('computes points to the next tier and null at the top', () => {
    expect(ownerReputationLevel(100)).toEqual({ tier: 'medium', score: 100, pointsToNext: 15 });
    expect(ownerReputationLevel(80)).toEqual({ tier: 'low', score: 80, pointsToNext: 10 });
    expect(ownerReputationLevel(130).pointsToNext).toBeNull();
  });
});
