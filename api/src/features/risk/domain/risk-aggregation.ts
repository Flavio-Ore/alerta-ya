import { SeedIncident } from '../infrastructure/seed-loader';

/** Tile espacial de DATACRIM (ml/data/processed/zones.json). Riesgo 0-100 (percentil de densidad). */
export interface DatacrimTile {
  lat: number;
  lng: number;
  risk: number;
  district: string;
}

export type RiskLevel = 'low' | 'moderate' | 'high';
export type Confidence = 'high' | 'medium' | 'low';

/** Estadística de riesgo de un distrito para una hora concreta. */
export interface HourStat {
  score: number; // 0-100
  level: RiskLevel;
  topType: string | null; // tipo más frecuente esa hora (null si sin datos)
  count: number; // nº de incidentes seed en ese distrito×hora
  confidence: Confidence;
}

export interface DistrictRisk {
  displayName: string;
  hourly: HourStat[]; // 24 entradas, índice = hora 0-23
  badHours: number[]; // top-3 horas más riesgosas
}

export interface RiskArtifact {
  tiles: DatacrimTile[]; // capa espacial para el heatmap
  districts: Record<string, DistrictRisk>; // clave = distrito normalizado
}

interface HourBucket {
  count: number;
  byType: Record<string, number>;
}

const N_SPARSE = 5; // umbral de confianza (spec: N=5)

/** Normaliza nombre de distrito para el join DATACRIM(MAYÚS sin tilde) ↔ seed/geo.utils. */
export function normalizeDistrict(name: string): string {
  return name
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .toUpperCase()
    .trim();
}

function levelFor(score: number): RiskLevel {
  if (score < 34) return 'low';
  if (score < 67) return 'moderate';
  return 'high';
}

/** Argmax determinista sobre un Record<tipo, count>. Desempata alfabéticamente. */
function argmaxType(byType: Record<string, number>): string | null {
  let best: string | null = null;
  let bestCount = -1;
  for (const key of Object.keys(byType).sort()) {
    if (byType[key]! > bestCount) {
      bestCount = byType[key]!;
      best = key;
    }
  }
  return best;
}

/** Agrupa el seed por distrito×hora (0-23). Hora derivada de createdAt. */
export function buildDistrictHourly(seed: SeedIncident[]): Record<string, HourBucket[]> {
  const out: Record<string, HourBucket[]> = {};
  for (const inc of seed) {
    const nd = normalizeDistrict(inc.district);
    const hour = new Date(inc.createdAt).getHours();
    if (Number.isNaN(hour)) continue;
    if (!out[nd]) {
      out[nd] = Array.from({ length: 24 }, () => ({ count: 0, byType: {} }));
    }
    const bucket = out[nd]![hour]!;
    bucket.count += 1;
    bucket.byType[inc.type] = (bucket.byType[inc.type] ?? 0) + 1;
  }
  return out;
}

/** Media de riesgo espacial (DATACRIM) por distrito normalizado + media global (fallback). */
function spatialBaseByDistrict(tiles: DatacrimTile[]): {
  byDistrict: Record<string, number>;
  global: number;
  displayNames: Record<string, string>;
} {
  const sum: Record<string, number> = {};
  const n: Record<string, number> = {};
  const displayNames: Record<string, string> = {};
  let gSum = 0;
  for (const t of tiles) {
    const nd = normalizeDistrict(t.district);
    sum[nd] = (sum[nd] ?? 0) + t.risk;
    n[nd] = (n[nd] ?? 0) + 1;
    displayNames[nd] ??= t.district;
    gSum += t.risk;
  }
  const byDistrict: Record<string, number> = {};
  for (const nd of Object.keys(sum)) byDistrict[nd] = sum[nd]! / n[nd]!;
  const global = tiles.length > 0 ? gSum / tiles.length : 0;
  return { byDistrict, global, displayNames };
}

const clamp = (v: number, lo: number, hi: number) => Math.max(lo, Math.min(hi, v));

/**
 * Combina la base espacial (DATACRIM, DÓNDE) con la señal temporal del seed
 * (CUÁNDO, por distrito×hora) en un artefacto de riesgo por hora.
 *
 * Escalera de confianza (N=5, degradación grácil — nunca un 0 preciso engañoso):
 *  - distrito×hora con ≥5 incidentes → 'high': factor temporal específico de la hora.
 *  - distrito con ≥5 incidentes totales → 'medium': sin especificidad horaria (factor 1).
 *  - menos → 'low': solo base espacial DATACRIM.
 */
export function computeRiskArtifact(tiles: DatacrimTile[], seed: SeedIncident[]): RiskArtifact {
  const hourly = buildDistrictHourly(seed);
  const { byDistrict, global, displayNames } = spatialBaseByDistrict(tiles);

  const districtKeys = new Set([...Object.keys(byDistrict), ...Object.keys(hourly)]);
  const districts: Record<string, DistrictRisk> = {};

  for (const nd of districtKeys) {
    const base = byDistrict[nd] ?? global;
    const buckets = hourly[nd] ?? Array.from({ length: 24 }, () => ({ count: 0, byType: {} }));
    const districtTotal = buckets.reduce((a, b) => a + b.count, 0);
    const meanHourCount = districtTotal / 24;

    // topType a nivel distrito (fallback para horas de baja confianza)
    const districtByType: Record<string, number> = {};
    for (const b of buckets) for (const [t, c] of Object.entries(b.byType)) districtByType[t] = (districtByType[t] ?? 0) + c;
    const districtTopType = argmaxType(districtByType);

    const hourlyStats: HourStat[] = buckets.map((b): HourStat => {
      let factor = 1;
      let confidence: Confidence;
      let topType: string | null;

      if (b.count >= N_SPARSE && meanHourCount > 0) {
        factor = clamp(0.5 + 0.5 * (b.count / meanHourCount), 0.5, 1.5);
        confidence = 'high';
        topType = argmaxType(b.byType);
      } else if (districtTotal >= N_SPARSE) {
        confidence = 'medium';
        topType = districtTopType;
      } else {
        confidence = 'low';
        topType = null;
      }

      const score = Math.round(clamp(base * factor, 0, 100));
      return { score, level: levelFor(score), topType, count: b.count, confidence };
    });

    const badHours = buckets
      .map((b, h) => ({ h, count: b.count }))
      .filter((x) => x.count > 0)
      .sort((a, b) => b.count - a.count || a.h - b.h)
      .slice(0, 3)
      .map((x) => x.h);

    districts[nd] = {
      displayName: displayNames[nd] ?? nd,
      hourly: hourlyStats,
      badHours,
    };
  }

  return { tiles, districts };
}
