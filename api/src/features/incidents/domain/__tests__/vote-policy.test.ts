import { describe, it, expect } from 'vitest';

import {
  isWithinVoteRange,
  voteWeight,
  shouldCloseByConsensus,
  VOTE_WEIGHTS,
  CLOSE_MIN_DISTINCT_DENIERS,
} from '../vote-policy';

describe('isWithinVoteRange', () => {
  it('true at the same point, false ~6km away', () => {
    expect(isWithinVoteRange(-12.06, -77.03, -12.06, -77.03)).toBe(true);
    expect(isWithinVoteRange(-12.06, -77.03, -12.1, -77.05)).toBe(false);
  });
});

describe('voteWeight', () => {
  it('maps reputation tier to weight (Sybil-resistant)', () => {
    expect(voteWeight(200)).toBe(VOTE_WEIGHTS.high); // high tier
    expect(voteWeight(100)).toBe(VOTE_WEIGHTS.medium); // default
    expect(voteWeight(50)).toBe(VOTE_WEIGHTS.low); // low tier
  });
});

describe('shouldCloseByConsensus', () => {
  it('requires BOTH weighted margin AND ≥K distinct deniers', () => {
    // margin met, but too few distinct → no close
    expect(shouldCloseByConsensus(10, 0, CLOSE_MIN_DISTINCT_DENIERS - 1)).toBe(false);
    // enough distinct, but margin not met → no close
    expect(shouldCloseByConsensus(2, 1, CLOSE_MIN_DISTINCT_DENIERS)).toBe(false);
    // both met → close
    expect(shouldCloseByConsensus(6, 1, CLOSE_MIN_DISTINCT_DENIERS)).toBe(true);
  });
});
