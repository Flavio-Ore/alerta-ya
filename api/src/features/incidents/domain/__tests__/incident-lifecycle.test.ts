import { describe, it, expect } from 'vitest';

import { cappedExtendedExpiry, MAX_INCIDENT_LIFE_MINUTES } from '../incident-lifecycle';

const createdAt = new Date('2026-01-01T00:00:00Z');

describe('cappedExtendedExpiry', () => {
  it('extends normally when still within the max-life window', () => {
    const currentExpiry = new Date('2026-01-01T00:20:00Z'); // +20min
    const result = cappedExtendedExpiry(currentExpiry, createdAt, 30);
    expect(result.toISOString()).toBe('2026-01-01T00:50:00.000Z'); // +30 → 50min < 90
  });

  it('clamps to createdAt + MAX_LIFE when the extension would exceed the cap', () => {
    const currentExpiry = new Date('2026-01-01T01:20:00Z'); // +80min
    const result = cappedExtendedExpiry(currentExpiry, createdAt, 30); // would be 110min
    expect(result.getTime()).toBe(createdAt.getTime() + MAX_INCIDENT_LIFE_MINUTES * 60_000);
    expect(result.toISOString()).toBe('2026-01-01T01:30:00.000Z'); // 90min
  });

  it('never exceeds the cap no matter how many times it is called', () => {
    let expiry = new Date('2026-01-01T00:20:00Z');
    for (let i = 0; i < 20; i++) {
      expiry = cappedExtendedExpiry(expiry, createdAt, 30);
    }
    expect(expiry.getTime()).toBe(createdAt.getTime() + MAX_INCIDENT_LIFE_MINUTES * 60_000);
  });
});
