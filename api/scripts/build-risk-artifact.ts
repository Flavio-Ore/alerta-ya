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
 * La lógica vive en src/features/risk/infrastructure/risk-recompute.ts para que el
 * job periódico (POST /internal/jobs/recompute-risk) reuse el mismo cálculo.
 *
 * Escribe:
 *   - api/data/risk-hourly.json        (lo lee el endpoint GET /risk)
 *   - web/public/data/risk-hourly.json (copia para uso web opcional)
 */
import { join } from 'node:path';

import { recomputeRiskArtifact } from '../src/features/risk/infrastructure/risk-recompute';

const API_ROOT = join(import.meta.dir, '..');
const REPO_ROOT = join(API_ROOT, '..');

const result = recomputeRiskArtifact({
  datacrimPath: join(REPO_ROOT, 'ml', 'data', 'processed', 'zones.json'),
  seedPath: join(API_ROOT, 'data', 'seed-incidents.json'),
  outApiPath: join(API_ROOT, 'data', 'risk-hourly.json'),
  outWebPath: join(REPO_ROOT, 'web', 'public', 'data', 'risk-hourly.json'),
});

console.log(
  `[risk-artifact] ${result.tiles} tiles + ${result.seed} seed → ${result.districts} districts`,
);
