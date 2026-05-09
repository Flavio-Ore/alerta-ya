import { describe, it, expect, vi, beforeEach } from 'vitest';

import { evaluateThreshold, ThresholdContext } from '../threshold.engine';

// Mock mínimo de ioredis para tests unitarios
function createRedisMock() {
  const store: Record<string, Record<string, string>> = {};

  const pipelineMock = {
    hsetnx: vi.fn().mockReturnThis(),
    hincrby: vi.fn().mockReturnThis(),
    expire: vi.fn().mockReturnThis(),
    hget: vi.fn().mockReturnThis(),
    exec: vi.fn(),
  };

  return {
    pipeline: vi.fn(() => pipelineMock),
    _pipelineMock: pipelineMock,
    _store: store,
  } as unknown as ReturnType<typeof createRedisMock>;
}

type RedisMock = ReturnType<typeof createRedisMock>;

function buildCtx(overrides: Partial<ThresholdContext> = {}): ThresholdContext {
  return {
    lat: -12.1167,
    lng: -77.0372,
    type: 'ROBBERY',
    reportId: 'report-001',
    formData: {},
    now: Date.now(),
    ...overrides,
  };
}

function mockPipelineResult(mock: RedisMock, count: number, firstAt: number, weapon = 0, injured = 0, stillHere = 0) {
  mock._pipelineMock.exec.mockResolvedValue([
    [null, 1],               // [0] hsetnx firstAt
    [null, count],           // [1] hincrby count
    [null, weapon],          // [2] hincrby formWeapon
    [null, injured],         // [3] hincrby formInjured
    [null, stillHere],       // [4] hincrby formStillHere
    [null, 1],               // [5] expire NX
    [null, firstAt.toString()], // [6] hget firstAt
  ]);
}

describe('ThresholdEngine', () => {
  let redisMock: RedisMock;

  beforeEach(() => {
    redisMock = createRedisMock();
    vi.clearAllMocks();
  });

  it('GIVEN 1 reporte WHEN evaluateThreshold THEN no publica', async () => {
    const now = Date.now();
    mockPipelineResult(redisMock, 1, now);

    const result = await evaluateThreshold(buildCtx({ now }), redisMock as never);

    expect(result.publish).toBe(false);
  });

  it('GIVEN 2 reportes dentro de 15min WHEN evaluateThreshold THEN publica LOW sin push', async () => {
    const now = Date.now();
    const firstAt = now - 5 * 60 * 1000; // hace 5 min
    mockPipelineResult(redisMock, 2, firstAt);

    const result = await evaluateThreshold(buildCtx({ now }), redisMock as never);

    expect(result.publish).toBe(true);
    expect(result.severity).toBe('LOW');
    expect(result.push).toBe(false);
  });

  it('GIVEN 3 reportes dentro de 15min WHEN evaluateThreshold THEN publica MODERATE con push', async () => {
    const now = Date.now();
    const firstAt = now - 8 * 60 * 1000;
    mockPipelineResult(redisMock, 3, firstAt);

    const result = await evaluateThreshold(buildCtx({ now }), redisMock as never);

    expect(result.publish).toBe(true);
    expect(result.severity).toBe('MODERATE');
    expect(result.push).toBe(true);
  });

  it('GIVEN 5 reportes WHEN evaluateThreshold THEN publica CRITICAL con push', async () => {
    const now = Date.now();
    const firstAt = now - 10 * 60 * 1000;
    mockPipelineResult(redisMock, 5, firstAt);

    const result = await evaluateThreshold(buildCtx({ now }), redisMock as never);

    expect(result.publish).toBe(true);
    expect(result.severity).toBe('CRITICAL');
    expect(result.push).toBe(true);
  });

  it('GIVEN 2 reportes después de 15min WHEN evaluateThreshold THEN no publica', async () => {
    const now = Date.now();
    const firstAt = now - 16 * 60 * 1000; // hace 16 min
    mockPipelineResult(redisMock, 2, firstAt);

    const result = await evaluateThreshold(buildCtx({ now }), redisMock as never);

    expect(result.publish).toBe(false);
  });

  it('GIVEN 3+ armas WHEN evaluateThreshold THEN escala a CRITICAL', async () => {
    const now = Date.now();
    const firstAt = now - 5 * 60 * 1000;
    mockPipelineResult(redisMock, 3, firstAt, 3, 0, 0); // 3 armas

    const result = await evaluateThreshold(buildCtx({ now }), redisMock as never);

    expect(result.severity).toBe('CRITICAL');
  });

  it('GIVEN 3+ heridos WHEN evaluateThreshold THEN escala a CRITICAL con alertPolice', async () => {
    const now = Date.now();
    const firstAt = now - 5 * 60 * 1000;
    mockPipelineResult(redisMock, 3, firstAt, 0, 3, 0); // 3 heridos

    const result = await evaluateThreshold(buildCtx({ now }), redisMock as never);

    expect(result.severity).toBe('CRITICAL');
    expect(result.alertPolice).toBe(true);
  });

  it('GIVEN 3+ stillHere WHEN evaluateThreshold THEN extiende expiración 30 min', async () => {
    const now = Date.now();
    const firstAt = now - 5 * 60 * 1000;
    mockPipelineResult(redisMock, 3, firstAt, 0, 0, 3); // 3 stillHere

    const result = await evaluateThreshold(buildCtx({ now }), redisMock as never);

    expect(result.extendExpiryMinutes).toBe(30);
  });

  it('GIVEN pipeline falla WHEN evaluateThreshold THEN no publica (fail open)', async () => {
    redisMock._pipelineMock.exec.mockResolvedValue(null);

    const result = await evaluateThreshold(buildCtx(), redisMock as never);

    expect(result.publish).toBe(false);
  });
});
