/**
 * Precompute del artefacto de riesgo (Fase F).
 *
 * Uso:
 *   bun run scripts/build-risk-artifact.ts
 *
 * Combina la base ESPACIAL de DATACRIM (ml/data/processed/zones.json — dónde) con
 * la señal TEMPORAL del seed (api/data/seed-incidents.json — cuándo, por hora) en
 * un artefacto por distrito×hora. Salida DETERMINISTA (sin timestamps) para que el
 * archivo generado sea reproducible y committeable.
 *
 * Escribe:
 *   - api/data/risk-hourly.json        (lo lee el endpoint GET /risk)
 *   - web/public/data/risk-hourly.json (copia para uso web opcional)
 */
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { join, dirname } from 'node:path';

import { computeRiskArtifact, DatacrimTile } from '../src/features/risk/domain/risk-aggregation';
import { loadSeedIncidents } from '../src/features/risk/infrastructure/seed-loader';

const API_ROOT = join(import.meta.dir, '..');
const REPO_ROOT = join(API_ROOT, '..');

const DATACRIM_ZONES = join(REPO_ROOT, 'ml', 'data', 'processed', 'zones.json');
const SEED_PATH = join(API_ROOT, 'data', 'seed-incidents.json');
const OUT_API = join(API_ROOT, 'data', 'risk-hourly.json');
const OUT_WEB = join(REPO_ROOT, 'web', 'public', 'data', 'risk-hourly.json');

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

function main(): void {
  const tiles = loadDatacrimTiles(DATACRIM_ZONES);
  const seed = loadSeedIncidents(SEED_PATH);
  const artifact = computeRiskArtifact(tiles, seed);

  writeJson(OUT_API, artifact);
  writeJson(OUT_WEB, artifact);

  const districtCount = Object.keys(artifact.districts).length;
  console.log(
    `[risk-artifact] ${tiles.length} tiles + ${seed.length} seed → ${districtCount} districts`,
  );
  console.log(`[risk-artifact] wrote ${OUT_API}`);
  console.log(`[risk-artifact] wrote ${OUT_WEB}`);
}

main();
