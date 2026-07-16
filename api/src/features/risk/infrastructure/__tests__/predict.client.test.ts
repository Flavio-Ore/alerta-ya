import { describe, it, expect, vi, afterEach } from 'vitest';

// env.ts valida process.env al cargar y hace process.exit(1) si falta algo —
// mockeamos para no depender del entorno (mismo patrón que glm.client.test).
vi.mock('../../../../core/config/env', () => ({
  env: { ML_SERVICE_URL: 'http://ml.test' },
}));

const { predictRisk } = await import('../predict.client');

const okBody = {
  risk_score: 100,
  expected_count: 2.651,
  confidence: 1.0,
  predicted_hour: 23,
  day_of_week: 5,
  degraded: false,
};

const input = { lat: -12.066, lng: -77.03, hour: 23, dayOfWeek: 5 };

afterEach(() => {
  vi.restoreAllMocks();
});

describe('predictRisk', () => {
  it('mapea la respuesta del ML service a PredictResult', async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn(async () => new Response(JSON.stringify(okBody), { status: 200 })),
    );
    const r = await predictRisk(input);
    expect(r).toEqual({
      riskScore: 100,
      expectedCount: 2.651,
      confidence: 1.0,
      hour: 23,
      dayOfWeek: 5,
    });
  });

  it('manda day_of_week (no dayOfWeek) al ML service — contrato snake_case', async () => {
    const fetchMock = vi.fn(async () => new Response(JSON.stringify(okBody), { status: 200 }));
    vi.stubGlobal('fetch', fetchMock);
    await predictRisk(input);
    const body = JSON.parse((fetchMock.mock.calls[0]![1] as RequestInit).body as string);
    expect(body).toMatchObject({ lat: -12.066, lng: -77.03, hour: 23, day_of_week: 5 });
    expect(body).not.toHaveProperty('dayOfWeek');
  });

  it('FAIL-OPEN: modelo degradado → null (no propaga un score falso)', async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn(async () => new Response(JSON.stringify({ ...okBody, degraded: true }), { status: 200 })),
    );
    expect(await predictRisk(input)).toBeNull();
  });

  it('FAIL-OPEN: 5xx del ML service → null', async () => {
    vi.stubGlobal('fetch', vi.fn(async () => new Response('err', { status: 503 })));
    expect(await predictRisk(input)).toBeNull();
  });

  it('FAIL-OPEN: la red lanza → null (nunca propaga la excepción)', async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn(async () => {
        throw new Error('ECONNREFUSED');
      }),
    );
    expect(await predictRisk(input)).toBeNull();
  });
});
