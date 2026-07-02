import { readFileSync } from 'node:fs';
import { join } from 'node:path';

/**
 * Registro de incidente del seed (api/data/seed-incidents.json), usado como
 * señal TEMPORAL (hora del día) para el motor de riesgo. Es data anónima
 * agregada — no contiene identidad del reportante.
 */
export interface SeedIncident {
  type: string;
  severity: string;
  district: string;
  lat: number;
  lng: number;
  createdAt: string; // ISO — la hora se deriva de acá
}

const INCIDENT_TYPES = new Set(['ROBBERY', 'ACCIDENT', 'HARASSMENT', 'EXTORTION', 'SUSPICIOUS']);
const SEVERITIES = new Set(['LOW', 'MODERATE', 'CRITICAL']);

// Lima Metropolitana bounding box (mismo criterio que geo.utils / DATACRIM).
const LIMA = { minLat: -12.4, maxLat: -11.5, minLng: -77.3, maxLng: -76.6 };

export const DEFAULT_SEED_PATH = join(process.cwd(), 'data', 'seed-incidents.json');

function isValidRow(row: unknown): row is SeedIncident {
  if (typeof row !== 'object' || row === null) return false;
  const r = row as Record<string, unknown>;
  if (!INCIDENT_TYPES.has(r['type'] as string)) return false;
  if (!SEVERITIES.has(r['severity'] as string)) return false;
  if (typeof r['district'] !== 'string' || r['district'].length === 0) return false;
  if (typeof r['lat'] !== 'number' || r['lat'] < LIMA.minLat || r['lat'] > LIMA.maxLat) return false;
  if (typeof r['lng'] !== 'number' || r['lng'] < LIMA.minLng || r['lng'] > LIMA.maxLng) return false;
  if (typeof r['createdAt'] !== 'string' || Number.isNaN(Date.parse(r['createdAt']))) return false;
  return true;
}

/**
 * Carga y valida el seed de incidentes. Fail-open: filas malformadas o fuera de
 * Lima se descartan silenciosamente; un archivo ausente/ilegible retorna [].
 * NUNCA lanza — el motor de riesgo debe degradar, no romper.
 */
export function loadSeedIncidents(path: string = DEFAULT_SEED_PATH): SeedIncident[] {
  let raw: string;
  try {
    raw = readFileSync(path, 'utf-8');
  } catch {
    return [];
  }

  let parsed: unknown;
  try {
    parsed = JSON.parse(raw);
  } catch {
    return [];
  }

  if (!Array.isArray(parsed)) return [];

  return parsed.filter(isValidRow).map((r) => ({
    type: r.type,
    severity: r.severity,
    district: r.district,
    lat: r.lat,
    lng: r.lng,
    createdAt: r.createdAt,
  }));
}
