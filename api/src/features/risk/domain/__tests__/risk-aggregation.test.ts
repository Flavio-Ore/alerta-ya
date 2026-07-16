import { describe, it, expect } from 'vitest';

import {
  normalizeDistrict,
  buildDistrictHourly,
  computeRiskArtifact,
  DatacrimTile,
} from '../risk-aggregation';
import { SeedIncident } from '../../infrastructure/seed-loader';

function inc(
  district: string,
  hour: number,
  type = 'ROBBERY',
  severity = 'LOW',
): SeedIncident {
  const hh = String(hour).padStart(2, '0');
  return { type, severity, district, lat: -12.1, lng: -77.0, createdAt: `2026-06-24T${hh}:30:00` };
}
function tile(district: string, risk: number): DatacrimTile {
  return { lat: -12.1, lng: -77.0, risk, district };
}

describe('normalizeDistrict', () => {
  it('uppercases and strips accents so DATACRIM and seed names join', () => {
    expect(normalizeDistrict('Barranco')).toBe('BARRANCO');
    expect(normalizeDistrict('San Martín de Porres')).toBe('SAN MARTIN DE PORRES');
  });
});

describe('buildDistrictHourly', () => {
  it('buckets incidents by district and hour derived from createdAt', () => {
    const h = buildDistrictHourly([inc('Barranco', 22), inc('Barranco', 22), inc('Barranco', 8)]);
    expect(h['BARRANCO']![22]!.count).toBe(2);
    expect(h['BARRANCO']![8]!.count).toBe(1);
    expect(h['BARRANCO']![22]!.byType['ROBBERY']).toBe(2);
  });
});

describe('computeRiskArtifact', () => {
  const tiles = [tile('BARRANCO', 60), tile('SPARSE', 40), tile('MED', 50)];

  it('HIGH confidence: a district×hour with >=5 incidents gets an hour-specific score + topType', () => {
    const seed = Array.from({ length: 6 }, () => inc('Barranco', 22, 'EXTORTION'));
    const art = computeRiskArtifact(tiles, seed);
    const h22 = art.districts['BARRANCO']!.hourly[22]!;
    expect(h22.confidence).toBe('high');
    expect(h22.topType).toBe('EXTORTION');
    expect(h22.count).toBe(6);
    // base 60 * factor up to 1.5 -> elevated, high level
    expect(h22.score).toBeGreaterThan(60);
    expect(h22.level).toBe('high');
  });

  it('LOW confidence (sparse): never a misleading precise-0 — falls back to spatial base', () => {
    const seed = [inc('Sparse', 3)]; // 1 incident, district total < 5
    const art = computeRiskArtifact(tiles, seed);
    const h3 = art.districts['SPARSE']!.hourly[3]!;
    expect(h3.confidence).toBe('low');
    expect(h3.score).toBe(40); // == spatial base, NOT 0
    expect(h3.topType).toBeNull();
  });

  it('MEDIUM confidence: district total >=5 but no single hour >=5 → no hour specificity', () => {
    const seed = [inc('Med', 1), inc('Med', 2), inc('Med', 3), inc('Med', 4), inc('Med', 5)];
    const art = computeRiskArtifact(tiles, seed);
    const h1 = art.districts['MED']!.hourly[1]!;
    expect(h1.confidence).toBe('medium');
    expect(h1.score).toBe(50); // base, factor 1
    expect(h1.topType).toBe('ROBBERY'); // district-level fallback topType
  });

  it('badHours = top-3 hours by count', () => {
    const seed = [
      ...Array.from({ length: 6 }, () => inc('Barranco', 22)),
      ...Array.from({ length: 4 }, () => inc('Barranco', 20)),
      ...Array.from({ length: 2 }, () => inc('Barranco', 8)),
      inc('Barranco', 3),
    ];
    const art = computeRiskArtifact(tiles, seed);
    expect(art.districts['BARRANCO']!.badHours).toEqual([22, 20, 8]);
  });

  it('is DETERMINISTIC: same inputs serialize to identical JSON (committeable artifact)', () => {
    const seed = [inc('Barranco', 22), inc('Med', 1), inc('Barranco', 22, 'EXTORTION')];
    const a = JSON.stringify(computeRiskArtifact(tiles, seed));
    const b = JSON.stringify(computeRiskArtifact(tiles, seed));
    expect(a).toBe(b);
  });

  it('passes tiles through for the heatmap and keys districts by normalized name', () => {
    const art = computeRiskArtifact(tiles, []);
    expect(art.tiles).toHaveLength(3);
    expect(Object.keys(art.districts).sort()).toEqual(['BARRANCO', 'MED', 'SPARSE']);
    // districts with no seed data still exist with low confidence (spatial-only)
    expect(art.districts['BARRANCO']!.hourly[0]!.confidence).toBe('low');
  });

  it('safestHours: ranks the least active hours when the district HAS an hourly signal', () => {
    const seed = [
      ...Array.from({ length: 6 }, () => inc('Barranco', 22)), // hora pico → 'high'
      ...Array.from({ length: 3 }, () => inc('Barranco', 20)),
      inc('Barranco', 8),
    ];
    const art = computeRiskArtifact(tiles, seed);
    // 0,1,2 no tienen incidentes y empatan en 0 → desempate por hora asc.
    expect(art.districts['BARRANCO']!.safestHours).toEqual([0, 1, 2]);
  });

  it('safestHours is EMPTY without a high-confidence hour (absence of evidence ≠ safe)', () => {
    // 4 incidentes: el distrito nunca llega a 'high' en ninguna hora.
    const seed = Array.from({ length: 4 }, () => inc('Barranco', 22));
    const art = computeRiskArtifact(tiles, seed);
    expect(art.districts['BARRANCO']!.hourly.some((h) => h.confidence === 'high')).toBe(false);
    expect(art.districts['BARRANCO']!.safestHours).toEqual([]);
  });

  it('topSeverity follows the SAME confidence ladder as topType', () => {
    const seed = [
      ...Array.from({ length: 5 }, () => inc('Barranco', 22, 'ROBBERY', 'CRITICAL')),
      inc('Barranco', 22, 'ROBBERY', 'LOW'),
      inc('Barranco', 3, 'ROBBERY', 'LOW'),
    ];
    const art = computeRiskArtifact(tiles, seed);
    const d = art.districts['BARRANCO']!;
    // hora 22: 6 incidentes → 'high' → severidad de ESA hora
    expect(d.hourly[22]!.confidence).toBe('high');
    expect(d.hourly[22]!.topSeverity).toBe('CRITICAL');
    // hora 3: 1 incidente pero el distrito tiene >=5 → 'medium' → fallback distrital
    expect(d.hourly[3]!.confidence).toBe('medium');
    expect(d.hourly[3]!.topSeverity).toBe('CRITICAL');
    // hora sin datos → 'medium' (distrito tiene señal) → fallback, nunca null acá
    expect(d.hourly[12]!.topSeverity).toBe('CRITICAL');
  });

  it('topSeverity is null when the district is too sparse to claim anything', () => {
    const art = computeRiskArtifact(tiles, [inc('Sparse', 22, 'ROBBERY', 'CRITICAL')]);
    expect(art.districts['SPARSE']!.hourly[22]!.confidence).toBe('low');
    expect(art.districts['SPARSE']!.hourly[22]!.topSeverity).toBeNull();
  });
});
