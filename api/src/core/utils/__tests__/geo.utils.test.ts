import { describe, it, expect } from 'vitest';

import { distanceMeters } from '../geo.utils';

describe('distanceMeters', () => {
  it('is zero for the same point', () => {
    expect(distanceMeters(-12.06, -77.03, -12.06, -77.03)).toBe(0);
  });

  it('approximates ~1km for 0.009° of latitude', () => {
    const d = distanceMeters(-12.06, -77.03, -12.069, -77.03);
    expect(d).toBeGreaterThan(950);
    expect(d).toBeLessThan(1050);
  });

  it('is symmetric', () => {
    const a = distanceMeters(-12.06, -77.03, -12.05, -77.02);
    const b = distanceMeters(-12.05, -77.02, -12.06, -77.03);
    expect(Math.abs(a - b)).toBeLessThan(1e-6);
  });
});
