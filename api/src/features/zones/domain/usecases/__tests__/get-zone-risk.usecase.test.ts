import { describe, it, expect, vi } from 'vitest';

import { getZoneRisk, RiskZoneRepository } from '../get-zone-risk.usecase';

const mockZone = {
  id: 'zone-001',
  district: 'Miraflores',
  lat: -12.1167,
  lng: -77.0372,
  riskScore: 72,
  predictedHour: 22,
  updatedAt: new Date('2024-01-01T00:00:00Z'),
};

function makeRepo(zone: typeof mockZone | null): RiskZoneRepository {
  return { findNearest: vi.fn().mockResolvedValue(zone) };
}

describe('getZoneRisk', () => {
  it('GIVEN coordenadas fuera de Lima WHEN llamado THEN lanza 422', async () => {
    const repo = makeRepo(null);
    await expect(getZoneRisk(0, 0, repo)).rejects.toMatchObject({ statusCode: 422 });
  });

  it('GIVEN coordenadas válidas y zona cercana WHEN llamado THEN retorna ZoneRiskDTO', async () => {
    const repo = makeRepo(mockZone);
    const result = await getZoneRisk(-12.1167, -77.0372, repo);

    expect(result.district).toBe('Miraflores');
    expect(result.riskScore).toBe(72);
    expect(result.predictedHour).toBe(22);
    expect(result.updatedAt).toBe('2024-01-01T00:00:00.000Z');
  });

  it('GIVEN coordenadas válidas y sin zona cercana WHEN llamado THEN retorna fallback riskScore 0', async () => {
    const repo = makeRepo(null);
    const result = await getZoneRisk(-12.1167, -77.0372, repo);

    expect(result.riskScore).toBe(0);
    expect(result.predictedHour).toBe(0);
    expect(result.district).toBe('Lima Metropolitana');
  });

  it('GIVEN zona encontrada THEN updatedAt es string ISO válido', async () => {
    const repo = makeRepo(mockZone);
    const result = await getZoneRisk(-12.1167, -77.0372, repo);

    expect(() => new Date(result.updatedAt)).not.toThrow();
    expect(new Date(result.updatedAt).toISOString()).toBe(result.updatedAt);
  });
});
