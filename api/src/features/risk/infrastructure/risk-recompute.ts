/**
 * Recompute del artefacto de riesgo (Fase I).
 *
 * Extrae la lógica reusable que antes vivía solo en scripts/build-risk-artifact.ts,
 * para que el mismo cálculo pueda dispararse:
 *   - offline, vía el script (build-risk-artifact.ts), o
 *   - periódicamente, vía el job POST /internal/jobs/recompute-risk.
 *
 * Determinista: sin timestamps, mismo input → mismo output committeable.
 */
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { join, dirname } from 'node:path';

import { computeRiskArtifact, DatacrimTile, RiskArtifact } from '../domain/risk-aggregation';
import { loadSeedIncidents } from './seed-loader';

export interface RecomputeOptions {
  /** DATACRIM tiles (base espacial). Default: <cwd>/../ml/data/processed/zones.json */
  datacrimPath?: string;
  /** Seed temporal. Default: <cwd>/data/seed-incidents.json */
  seedPath?: string;
  /** Si false, solo calcula (no escribe archivos). Default: true */
  write?: boolean;
  /** Salida que lee el endpoint. Default: <cwd>/data/risk-hourly.json */
  outApiPath?: string;
  /** Copia opcional para web. Default: <cwd>/../web/public/data/risk-hourly.json */
  outWebPath?: string;
}

export interface RecomputeResult {
  artifact: RiskArtifact;
  tiles: number;
  seed: number;
  districts: number;
}

function loadDatacrimTiles(path: string): DatacrimTile[] {
  const raw = JSON.parse(readFileSync(path, 'utf-8')) as Array<Record<string, unknown>>;
  return raw
    .filter(
      (t) =>
        typeof t['lat'] === 'number' &&
        typeof t['lng'] === 'number' &&
        typeof t['risk'] === 'number' &&
        typeof t['district'] === 'string',
    )
    .map((t) => ({
      lat: t['lat'] as number,
      lng: t['lng'] as number,
      risk: t['risk'] as number,
      district: t['district'] as string,
    }));
}

function writeJson(path: string, data: unknown): void {
  mkdirSync(dirname(path), { recursive: true });
  writeFileSync(path, JSON.stringify(data));
}

/**
 * Recalcula el artefacto de riesgo a partir de los archivos de datos.
 * Fail-fast en lectura (si falta zones.json el error sube al caller — el job lo captura).
 */
export function recomputeRiskArtifact(opts: RecomputeOptions = {}): RecomputeResult {
  const cwd = process.cwd();
  const datacrimPath =
    opts.datacrimPath ?? join(cwd, '..', 'ml', 'data', 'processed', 'zones.json');
  const seedPath = opts.seedPath ?? join(cwd, 'data', 'seed-incidents.json');
  const outApiPath = opts.outApiPath ?? join(cwd, 'data', 'risk-hourly.json');
  const outWebPath = opts.outWebPath ?? join(cwd, '..', 'web', 'public', 'data', 'risk-hourly.json');
  const write = opts.write ?? true;

  const tiles = loadDatacrimTiles(datacrimPath);
  const seed = loadSeedIncidents(seedPath);
  const artifact = computeRiskArtifact(tiles, seed);

  if (write) {
    writeJson(outApiPath, artifact);
    writeJson(outWebPath, artifact);
  }

  return {
    artifact,
    tiles: tiles.length,
    seed: seed.length,
    districts: Object.keys(artifact.districts).length,
  };
}
