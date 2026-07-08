import { describe, it, expect } from 'vitest';

import { computeReputationDelta, REPUTATION_DELTAS } from '../reputation';

describe('computeReputationDelta', () => {
  it('returns +5 when verified with evidence', () => {
    expect(computeReputationDelta(true, true)).toBe(REPUTATION_DELTAS.VERIFIED_WITH_EVIDENCE);
    expect(computeReputationDelta(true, true)).toBe(5);
  });

  it('returns +3 when verified without evidence', () => {
    expect(computeReputationDelta(true, false)).toBe(REPUTATION_DELTAS.VERIFIED_NO_EVIDENCE);
    expect(computeReputationDelta(true, false)).toBe(3);
  });

  it('returns -1 when suspicious with evidence', () => {
    expect(computeReputationDelta(false, true)).toBe(REPUTATION_DELTAS.SUSPICIOUS_WITH_EVIDENCE);
    expect(computeReputationDelta(false, true)).toBe(-1);
  });

  it('returns -2 when suspicious without evidence', () => {
    expect(computeReputationDelta(false, false)).toBe(REPUTATION_DELTAS.SUSPICIOUS_NO_EVIDENCE);
    expect(computeReputationDelta(false, false)).toBe(-2);
  });
});
