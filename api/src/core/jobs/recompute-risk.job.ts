/**
 * Job de recompute del artefacto de riesgo (Fase I).
 *
 * Recalcula api/data/risk-hourly.json y refresca el cache en memoria del endpoint
 * GET /risk. Pensado para correr periódicamente vía Cloud Scheduler (ver
 * docs/architecture/RETRAINING.md). Fail-safe: cualquier error se reporta al caller
 * sin tumbar el proceso.
 */
import { recomputeRiskArtifact } from '../../features/risk/infrastructure/risk-recompute';
import { reloadRiskArtifact } from '../../features/risk/infrastructure/risk-artifact.repository';

export interface RecomputeRiskJobResult {
  ok: boolean;
  tiles?: number;
  seed?: number;
  districts?: number;
  error?: string;
}

export function recomputeRiskJob(): RecomputeRiskJobResult {
  try {
    const { tiles, seed, districts } = recomputeRiskArtifact();
    reloadRiskArtifact(); // invalida el cache para que el endpoint sirva lo nuevo
    return { ok: true, tiles, seed, districts };
  } catch (err) {
    return { ok: false, error: err instanceof Error ? err.message : String(err) };
  }
}
