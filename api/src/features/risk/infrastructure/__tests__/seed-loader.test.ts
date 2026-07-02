import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { writeFileSync, rmSync, mkdtempSync } from 'node:fs';
import { join } from 'node:path';
import { tmpdir } from 'node:os';

import { loadSeedIncidents, DEFAULT_SEED_PATH } from '../seed-loader';

let dir: string;
const p = (name: string) => join(dir, name);

beforeAll(() => {
  dir = mkdtempSync(join(tmpdir(), 'seed-loader-'));
});
afterAll(() => {
  rmSync(dir, { recursive: true, force: true });
});

const valid = {
  type: 'ROBBERY',
  severity: 'LOW',
  status: 'ACTIVE',
  district: 'Barranco',
  lat: -12.15,
  lng: -77.02,
  createdAt: '2026-06-24T23:43:33',
};

describe('loadSeedIncidents', () => {
  it('GIVEN a valid array THEN loads and normalizes the temporal fields', () => {
    writeFileSync(p('ok.json'), JSON.stringify([valid, { ...valid, type: 'EXTORTION' }]));
    const result = loadSeedIncidents(p('ok.json'));
    expect(result).toHaveLength(2);
    expect(result[0]).toEqual({
      type: 'ROBBERY',
      severity: 'LOW',
      district: 'Barranco',
      lat: -12.15,
      lng: -77.02,
      createdAt: '2026-06-24T23:43:33',
    });
  });

  it('FAIL-OPEN: skips malformed rows (bad enum, out-of-Lima, missing fields) but keeps valid ones', () => {
    writeFileSync(
      p('mixed.json'),
      JSON.stringify([
        valid,
        { ...valid, type: 'NOT_A_TYPE' }, // bad enum
        { ...valid, severity: 'HUGE' }, // bad severity
        { ...valid, lat: 40.7 }, // outside Lima
        { ...valid, createdAt: 'not-a-date' }, // bad date
        { district: 'X' }, // missing fields
        null,
        'garbage',
      ]),
    );
    const result = loadSeedIncidents(p('mixed.json'));
    expect(result).toHaveLength(1);
    expect(result[0]!.type).toBe('ROBBERY');
  });

  it('GIVEN a missing file THEN returns [] (never throws)', () => {
    expect(loadSeedIncidents(p('does-not-exist.json'))).toEqual([]);
  });

  it('GIVEN invalid JSON THEN returns [] (never throws)', () => {
    writeFileSync(p('bad.json'), '{ not valid json');
    expect(loadSeedIncidents(p('bad.json'))).toEqual([]);
  });

  it('GIVEN a non-array JSON THEN returns []', () => {
    writeFileSync(p('obj.json'), JSON.stringify({ foo: 'bar' }));
    expect(loadSeedIncidents(p('obj.json'))).toEqual([]);
  });

  it('loads the real committed seed (api/data/seed-incidents.json) with all rows valid', () => {
    const result = loadSeedIncidents(DEFAULT_SEED_PATH);
    expect(result.length).toBeGreaterThan(300);
    expect(result.every((r) => r.district.length > 0 && !Number.isNaN(Date.parse(r.createdAt)))).toBe(
      true,
    );
  });
});
