import { readFileSync } from 'node:fs';
import { join } from 'node:path';

import { RiskArtifact } from '../domain/risk-aggregation';

const ARTIFACT_PATH = join(process.cwd(), 'data', 'risk-hourly.json');

let cache: RiskArtifact | null | undefined;

/**
 * Carga el artefacto de riesgo precomputado (api/data/risk-hourly.json) una sola
 * vez en memoria. Fail-open: si falta o es inválido, retorna null y el endpoint
 * degrada — nunca lanza.
 */
export function getRiskArtifact(): RiskArtifact | null {
  if (cache !== undefined) return cache;
  try {
    const parsed = JSON.parse(readFileSync(ARTIFACT_PATH, 'utf-8')) as RiskArtifact;
    cache = parsed && Array.isArray(parsed.tiles) && parsed.districts ? parsed : null;
  } catch {
    cache = null;
  }
  return cache;
}

/** Solo para tests: resetea el cache. */
export function __resetRiskArtifactCache(): void {
  cache = undefined;
}
