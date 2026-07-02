import { describe, it, expect } from 'vitest';

import { aiVerdict } from './aiVerdict';

describe('aiVerdict', () => {
  it('GIVEN score=null THEN returns not-evaluated', () => {
    expect(aiVerdict(null, null)).toBe('not-evaluated');
  });

  it('GIVEN score=0.9 AND verified=true THEN returns verified', () => {
    expect(aiVerdict(0.9, true)).toBe('verified');
  });

  it('GIVEN score=0.3 AND verified=false THEN returns suspicious', () => {
    expect(aiVerdict(0.3, false)).toBe('suspicious');
  });

  it('GIVEN score=0.5 AND verified=null (regression guard) THEN returns not-evaluated, NEVER verified', () => {
    expect(aiVerdict(0.5, null)).toBe('not-evaluated');
  });

  it('GIVEN score=0.5 AND verified=undefined (regression guard) THEN returns not-evaluated, NEVER verified', () => {
    expect(aiVerdict(0.5, undefined)).toBe('not-evaluated');
  });

  it('GIVEN score=undefined THEN returns not-evaluated', () => {
    expect(aiVerdict(undefined, true)).toBe('not-evaluated');
  });
});
