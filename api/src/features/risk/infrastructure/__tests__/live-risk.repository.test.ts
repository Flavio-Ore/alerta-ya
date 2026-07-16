import { describe, it, expect, beforeEach, vi } from 'vitest';

import {
  toLimaNaiveIso,
  loadLiveIncidents,
  getLiveRiskArtifact,
  __resetLiveRiskCache,
} from '../live-risk.repository';
import { __resetRiskArtifactCache } from '../risk-artifact.repository';

/** Prisma mínimo: solo lo que toca live-risk.repository. */
function fakePrisma(opts: {
  count?: number;
  maxAt?: Date | null;
  rows?: unknown[];
  throws?: boolean;
}) {
  const aggregate = vi.fn(async () => {
    if (opts.throws) throw new Error('Cloud SQL unreachable');
    return { _count: { _all: opts.count ?? 0 }, _max: { createdAt: opts.maxAt ?? null } };
  });
  const findMany = vi.fn(async () => opts.rows ?? []);
  return { incident: { aggregate, findMany } } as never;
}

function row(createdAt: Date, district = 'JESUS MARIA') {
  return {
    type: 'ROBBERY',
    severity: 'CRITICAL',
    district,
    lat: -12.075,
    lng: -77.048,
    createdAt,
  };
}

beforeEach(() => {
  __resetLiveRiskCache();
  __resetRiskArtifactCache();
});

describe('toLimaNaiveIso', () => {
  it('convierte un instante UTC a la hora de pared de Lima (UTC-5)', () => {
    // 02:30 UTC del 16-jul == 21:30 del 15-jul en Lima
    expect(toLimaNaiveIso(new Date('2026-07-16T02:30:00.000Z'))).toBe('2026-07-15T21:30:00');
  });

  it('el resultado round-trippea a la hora de Lima con getHours (lo que usa el motor)', () => {
    const utc = new Date('2026-07-16T02:30:00.000Z'); // 21:30 en Lima
    const hour = new Date(toLimaNaiveIso(utc)).getHours();
    expect(hour).toBe(21);
  });

  it('SIN la conversión el motor leería la hora corrida (regresión que protege este test)', () => {
    const utc = new Date('2026-07-16T02:30:00.000Z');
    // Pasar el ISO crudo con Z es el bug: en un contenedor UTC daría 2, no 21.
    const naive = toLimaNaiveIso(utc);
    expect(naive).not.toContain('Z');
    expect(naive.slice(11, 13)).toBe('21');
  });

  it('cruza correctamente el límite de día hacia atrás', () => {
    // 03:00 UTC del 1-ene == 22:00 del 31-dic en Lima
    expect(toLimaNaiveIso(new Date('2026-01-01T03:00:00.000Z'))).toBe('2025-12-31T22:00:00');
  });
});

describe('loadLiveIncidents', () => {
  it('mapea filas de BD al contrato del motor, con la hora en zona de Lima', async () => {
    const prisma = fakePrisma({ rows: [row(new Date('2026-07-16T02:30:00.000Z'))] });
    const out = await loadLiveIncidents(prisma);
    expect(out).toHaveLength(1);
    expect(out[0]!.district).toBe('JESUS MARIA');
    expect(out[0]!.createdAt).toBe('2026-07-15T21:30:00');
  });
});

describe('getLiveRiskArtifact', () => {
  it('FAIL-OPEN: si la BD falla sirve el artefacto horneado, nunca lanza', async () => {
    const artifact = await getLiveRiskArtifact(fakePrisma({ throws: true }));
    // El artefacto committeado existe → no es null y trae distritos.
    expect(artifact).not.toBeNull();
    expect(Object.keys(artifact!.districts).length).toBeGreaterThan(0);
  });

  it('con la tabla vacía produce el artefacto del seed (misma señal que hoy)', async () => {
    const artifact = await getLiveRiskArtifact(fakePrisma({ count: 0 }));
    expect(artifact!.districts['JESUS MARIA']!.hourly[21]!.confidence).toBe('high');
  });

  it('NO recalcula si el watermark no cambió — sirve cache', async () => {
    const prisma = fakePrisma({ count: 3, maxAt: new Date('2026-07-15T10:00:00Z') });
    await getLiveRiskArtifact(prisma);
    await getLiveRiskArtifact(prisma);
    await getLiveRiskArtifact(prisma);

    // El watermark se consulta siempre (es barato); findMany solo en el recompute.
    expect(prisma.incident.aggregate).toHaveBeenCalledTimes(3);
    expect(prisma.incident.findMany).toHaveBeenCalledTimes(1);
  });

  it('NO depende de ml/data/processed/zones.json — usa los tiles del horneado', async () => {
    // El build context del Dockerfile es ./api, así que ml/ no existe en la imagen.
    // Si el merge releyera zones.json, en Cloud Run lanzaría ENOENT y degradaría
    // siempre en silencio. Los tiles deben salir del artefacto horneado.
    const at21Lima = new Date('2026-07-16T02:30:00.000Z');
    const merged = await getLiveRiskArtifact(
      fakePrisma({ count: 1, maxAt: at21Lima, rows: [row(at21Lima, 'MIRAFLORES')] }),
    );
    const baked = (await import('../risk-artifact.repository')).getRiskArtifact();
    expect(merged!.tiles).toHaveLength(baked!.tiles.length);
    expect(merged!.tiles[0]).toEqual(baked!.tiles[0]);
  });

  it('SUMA los incidentes reales al seed en vez de reemplazarlo', async () => {
    // Miraflores 21h no está saturado (base 48): un reporte real debe moverlo.
    const baseArt = await getLiveRiskArtifact(fakePrisma({ count: 0 }));
    const before = baseArt!.districts['MIRAFLORES']!.hourly[21]!.score;

    __resetLiveRiskCache();
    const at21Lima = new Date('2026-07-16T02:30:00.000Z'); // 21:30 Lima
    const withLive = await getLiveRiskArtifact(
      fakePrisma({
        count: 3,
        maxAt: at21Lima,
        rows: Array.from({ length: 3 }, () => row(at21Lima, 'MIRAFLORES')),
      }),
    );
    const after = withLive!.districts['MIRAFLORES']!.hourly[21]!.score;

    expect(after).toBeGreaterThan(before);
    // El seed sigue vivo: los otros distritos conservan su señal.
    expect(withLive!.districts['JESUS MARIA']!.hourly[21]!.confidence).toBe('high');
  });
});
