import { describe, it, expect } from 'vitest';

import { getRisk } from '../get-risk.usecase';
import { getDistrict } from '../../../../../core/utils/geo.utils';
import { normalizeDistrict, RiskArtifact, HourStat } from '../../risk-aggregation';

const LAT = -12.06;
const LNG = -77.03; // dentro de Lima

function hourStat(score: number, over: Partial<HourStat> = {}): HourStat {
  return { score, level: 'high', topType: 'ROBBERY', count: 6, confidence: 'high', ...over };
}

function artifactAt(key: string): RiskArtifact {
  const hourly = Array.from({ length: 24 }, (_, h) => hourStat(h === 10 ? 80 : 20, h === 10 ? {} : { level: 'low', confidence: 'low', topType: null, count: 0 }));
  return {
    tiles: [{ lat: LAT, lng: LNG, risk: 55, district: key }],
    districts: { [key]: { displayName: 'Zona X', hourly, badHours: [10] } },
  };
}

describe('getRisk', () => {
  it('THROWS 422 for coordinates outside Lima', () => {
    expect(() => getRisk(40.7, -74.0, 10, null)).toThrow(/Lima/);
    expect(() => getRisk(40.7, -74.0, 10, null)).toThrowError(
      expect.objectContaining({ statusCode: 422 }),
    );
  });

  it('FAIL-OPEN: null artifact THEN returns unknown/null (never crash)', () => {
    const dto = getRisk(LAT, LNG, 10, null);
    expect(dto.riskScore).toBeNull();
    expect(dto.level).toBe('unknown');
    expect(dto.confidence).toBe('none');
    expect(dto.nearbyTiles).toEqual([]);
  });

  it('resolves the district + hour stat from the artifact', () => {
    const key = normalizeDistrict(getDistrict(LAT, LNG));
    const dto = getRisk(LAT, LNG, 10, artifactAt(key));
    expect(dto.riskScore).toBe(80);
    expect(dto.level).toBe('high');
    expect(dto.hour).toBe(10);
    expect(dto.badHours).toEqual([10]);
    expect(dto.nearbyTiles).toHaveLength(1);
  });

  it('DTO is anonymous — exposes only aggregate fields, no reporter identity', () => {
    const key = normalizeDistrict(getDistrict(LAT, LNG));
    const dto = getRisk(LAT, LNG, 10, artifactAt(key));
    expect(Object.keys(dto).sort()).toEqual(
      ['badHours', 'confidence', 'district', 'hour', 'level', 'nearbyTiles', 'riskScore', 'topType'].sort(),
    );
  });
});
