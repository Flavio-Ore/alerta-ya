import { describe, it, expect } from 'vitest';
import { join } from 'node:path';

import { recomputeRiskArtifact } from '../risk-recompute';

const API_ROOT = process.cwd(); // vitest corre desde la raíz de api/
const REPO_ROOT = join(API_ROOT, '..');

describe('recomputeRiskArtifact', () => {
  it('builds a non-empty artifact from the committed data files (no write)', () => {
    const result = recomputeRiskArtifact({
      datacrimPath: join(REPO_ROOT, 'ml', 'data', 'processed', 'zones.json'),
      seedPath: join(API_ROOT, 'data', 'seed-incidents.json'),
      write: false,
    });

    expect(result.tiles).toBeGreaterThan(0);
    expect(result.districts).toBeGreaterThan(0);
    expect(Array.isArray(result.artifact.tiles)).toBe(true);
    expect(Object.keys(result.artifact.districts).length).toBe(result.districts);
  });

  it('is deterministic — same input yields identical output', () => {
    const opts = {
      datacrimPath: join(REPO_ROOT, 'ml', 'data', 'processed', 'zones.json'),
      seedPath: join(API_ROOT, 'data', 'seed-incidents.json'),
      write: false,
    };
    const a = recomputeRiskArtifact(opts);
    const b = recomputeRiskArtifact(opts);
    expect(JSON.stringify(a.artifact)).toBe(JSON.stringify(b.artifact));
  });
});
