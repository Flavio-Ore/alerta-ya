import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';

vi.mock('../../../../core/config/env', () => ({
  env: {
    GLM_API_KEY: 'test-api-key',
    GLM_API_URL: 'https://api.z.ai/api/coding/paas/v4/chat/completions',
    GLM_MODEL: 'glm-4.7',
    GLM_TIMEOUT_MS: 50,
  },
}));

const { analyzeHistoricalData, streamHistoricalData } = await import('../glm.client');

const context = {
  districts: [{ district: 'Lima', risk: 80, count: 100 }],
  types: [{ type: 'Robo', count: 100 }],
};

describe('analyzeHistoricalData', () => {
  beforeEach(() => {
    vi.useFakeTimers();
  });

  afterEach(() => {
    vi.useRealTimers();
    vi.unstubAllGlobals();
    vi.restoreAllMocks();
  });

  it('GIVEN respuesta válida WHEN GLM responde THEN retorna el contenido', async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn().mockResolvedValue(
        new Response(
          JSON.stringify({ choices: [{ message: { content: 'Respuesta IA' } }] }),
          { status: 200 },
        ),
      ),
    );

    const result = await analyzeHistoricalData('¿Qué distrito priorizar?', context);

    expect(result).toEqual({ ok: true, answer: 'Respuesta IA' });
    const requestBody = JSON.parse(
      String(vi.mocked(fetch).mock.calls[0]?.[1]?.body),
    ) as { thinking?: { type?: string }; tools?: unknown };
    // `thinking` se removió: glm-4-flash (GLM-4) lo rechaza con 400.
    expect(requestBody.thinking).toBeUndefined();
    expect(requestBody.tools).toBeUndefined();
  });

  it('GIVEN proveedor lento WHEN supera el timeout THEN retorna timeout', async () => {
    vi.spyOn(console, 'error').mockImplementation(() => undefined);
    vi.stubGlobal(
      'fetch',
      vi.fn((_url: string | URL | Request, init?: RequestInit) =>
        new Promise((_resolve, reject) => {
          init?.signal?.addEventListener('abort', () => {
            const error = new Error('Request aborted');
            error.name = 'AbortError';
            reject(error);
          });
        }),
      ),
    );

    const resultPromise = analyzeHistoricalData('hola', context);
    await vi.advanceTimersByTimeAsync(50);

    await expect(resultPromise).resolves.toEqual({ ok: false, reason: 'timeout' });
  });

  it('GIVEN error HTTP WHEN GLM rechaza THEN retorna provider_error', async () => {
    vi.spyOn(console, 'error').mockImplementation(() => undefined);
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue(new Response(null, { status: 429 })));

    const result = await analyzeHistoricalData('hola', context);

    expect(result).toEqual({ ok: false, reason: 'provider_error' });
  });

  it('GIVEN stream SSE WHEN GLM emite contenido THEN entrega deltas incrementales', async () => {
    const encoder = new TextEncoder();
    const body = new ReadableStream<Uint8Array>({
      start(controller) {
        controller.enqueue(
          encoder.encode(
            'data: {"choices":[{"delta":{"content":"Hola "}}]}\n\n',
          ),
        );
        controller.enqueue(
          encoder.encode(
            'data: {"choices":[{"delta":{"content":"Lima"}}]}\n\ndata: [DONE]\n\n',
          ),
        );
        controller.close();
      },
    });
    vi.stubGlobal(
      'fetch',
      vi.fn().mockResolvedValue(new Response(body, { status: 200 })),
    );

    const chunks: string[] = [];
    for await (const chunk of streamHistoricalData('hola', context)) {
      chunks.push(chunk);
    }

    expect(chunks).toEqual(['Hola ', 'Lima']);
    expect(vi.mocked(fetch).mock.calls[0]?.[1]?.body).toContain(
      '"stream":true',
    );
  });
});
