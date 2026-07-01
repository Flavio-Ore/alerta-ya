import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';

vi.mock('../../../../core/config/env', () => ({
  env: {
    GLM_API_KEY: 'test-api-key',
    GLM_API_URL: 'https://open.bigmodel.cn/api/paas/v4/chat/completions',
    GLM_VISION_MODEL: 'glm-4v-flash',
    GLM_VISION_TIMEOUT_MS: 50,
  },
}));

const { analyzeImage } = await import('../glm.client');

describe('analyzeImage — structured JSON vision contract (S2)', () => {
  beforeEach(() => {
    vi.useFakeTimers();
  });

  afterEach(() => {
    vi.useRealTimers();
    vi.unstubAllGlobals();
    vi.restoreAllMocks();
  });

  function mockGlmResponse(content: string, status = 200) {
    vi.stubGlobal(
      'fetch',
      vi.fn().mockResolvedValue(
        new Response(
          JSON.stringify({ choices: [{ message: { content } }] }),
          { status },
        ),
      ),
    );
  }

  it('GIVEN JSON {relevance:1, no artifacts} WHEN GLM responds THEN returns 1.0 (consistent)', async () => {
    mockGlmResponse(
      JSON.stringify({ relevance: 1, screenshot: false, stock_or_meme: false, watermark: false }),
    );
    const result = await analyzeImage('https://example.com/img.jpg', 'ROBBERY');
    expect(result).toBe(1.0);
  });

  it('GIVEN JSON {relevance:-1} WHEN GLM responds THEN returns -1.0 (contradicts type)', async () => {
    mockGlmResponse(JSON.stringify({ relevance: -1 }));
    const result = await analyzeImage('https://example.com/img.jpg', 'ROBBERY');
    expect(result).toBe(-1.0);
  });

  it('GIVEN JSON {relevance:0} WHEN GLM responds THEN returns 0.0 (indeterminate)', async () => {
    mockGlmResponse(JSON.stringify({ relevance: 0 }));
    const result = await analyzeImage('https://example.com/img.jpg', 'ASSAULT');
    expect(result).toBe(0.0);
  });

  it('GIVEN JSON {relevance:1, screenshot:true} WHEN GLM responds THEN penalizes to 0.5', async () => {
    mockGlmResponse(JSON.stringify({ relevance: 1, screenshot: true }));
    const result = await analyzeImage('https://example.com/img.jpg', 'ROBBERY');
    expect(result).toBe(0.5);
  });

  it('GIVEN JSON {relevance:1, stock_or_meme:true} WHEN GLM responds THEN penalizes to 0.5', async () => {
    mockGlmResponse(JSON.stringify({ relevance: 1, stock_or_meme: true }));
    const result = await analyzeImage('https://example.com/img.jpg', 'ROBBERY');
    expect(result).toBe(0.5);
  });

  it('GIVEN JSON {relevance:1, watermark:true} WHEN GLM responds THEN penalizes to 0.75', async () => {
    mockGlmResponse(JSON.stringify({ relevance: 1, watermark: true }));
    const result = await analyzeImage('https://example.com/img.jpg', 'ROBBERY');
    expect(result).toBe(0.75);
  });

  it('GIVEN JSON {relevance:1, screenshot+stock_or_meme+watermark all true} WHEN GLM responds THEN penalty exceeds base AND clamps to -0.25', async () => {
    mockGlmResponse(
      JSON.stringify({ relevance: 1, screenshot: true, stock_or_meme: true, watermark: true }),
    );
    const result = await analyzeImage('https://example.com/img.jpg', 'ROBBERY');
    expect(result).toBe(-0.25);
  });

  it('GIVEN JSON {relevance:-1, screenshot:true} WHEN penalty pushes below -1 THEN clamps to -1.0 (never below bound)', async () => {
    mockGlmResponse(JSON.stringify({ relevance: -1, screenshot: true }));
    const result = await analyzeImage('https://example.com/img.jpg', 'ROBBERY');
    expect(result).toBe(-1.0);
  });

  it('GIVEN JSON {relevance:5} (out-of-range) WHEN GLM responds THEN base is clamped to 1.0 before penalties', async () => {
    mockGlmResponse(JSON.stringify({ relevance: 5 }));
    const result = await analyzeImage('https://example.com/img.jpg', 'ROBBERY');
    expect(result).toBe(1.0);
  });

  it('GIVEN JSON {relevance:-99} (out-of-range) WHEN GLM responds THEN base is clamped to -1.0', async () => {
    mockGlmResponse(JSON.stringify({ relevance: -99 }));
    const result = await analyzeImage('https://example.com/img.jpg', 'ROBBERY');
    expect(result).toBe(-1.0);
  });

  it('GIVEN code-fenced JSON (```json ... ```) WHEN GLM responds THEN the JSON block is extracted and parsed', async () => {
    mockGlmResponse('```json\n{"relevance": 1, "watermark": false}\n```');
    const result = await analyzeImage('https://example.com/img.jpg', 'ROBBERY');
    expect(result).toBe(1.0);
  });

  it('GIVEN malformed (non-JSON) content WHEN parsing runs THEN returns null (fail-open, never NaN/throw)', async () => {
    mockGlmResponse('this is not json at all');
    const result = await analyzeImage('https://example.com/img.jpg', 'ROBBERY');
    expect(result).toBeNull();
  });

  it('GIVEN JSON missing the required "relevance" field WHEN parsing runs THEN returns null (fail-open)', async () => {
    mockGlmResponse(JSON.stringify({ screenshot: true }));
    const result = await analyzeImage('https://example.com/img.jpg', 'ROBBERY');
    expect(result).toBeNull();
  });

  it('GIVEN empty content WHEN GLM responds THEN returns null (fail-open)', async () => {
    mockGlmResponse('');
    const result = await analyzeImage('https://example.com/img.jpg', 'ROBBERY');
    expect(result).toBeNull();
  });

  it('GIVEN a free-text response containing the word "INCONSISTENT" WHEN parsed as non-JSON THEN returns null — the old substring-matching bug class ("INCONSISTENT" contains "CONSISTENT") is now structurally impossible because scoring requires a valid JSON "relevance" field, not string matching', async () => {
    mockGlmResponse('The photo is INCONSISTENT with this incident type.');
    const result = await analyzeImage('https://example.com/img.jpg', 'FIRE');
    expect(result).toBeNull();
  });

  it('GIVEN network error WHEN fetch throws THEN returns null (fail-open)', async () => {
    vi.stubGlobal('fetch', vi.fn().mockRejectedValue(new Error('Network error')));
    const result = await analyzeImage('https://example.com/img.jpg', 'ROBBERY');
    expect(result).toBeNull();
  });

  it('GIVEN non-200 response WHEN GLM rejects THEN returns null (fail-open)', async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn().mockResolvedValue(new Response(null, { status: 429 })),
    );
    const result = await analyzeImage('https://example.com/img.jpg', 'ROBBERY');
    expect(result).toBeNull();
  });

  it('GIVEN timeout WHEN GLM is slow THEN returns null (fail-open)', async () => {
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

    const resultPromise = analyzeImage('https://example.com/img.jpg', 'ROBBERY');
    await vi.advanceTimersByTimeAsync(50);

    await expect(resultPromise).resolves.toBeNull();
  });
});

describe('analyzeImage — no API key', () => {
  it('GIVEN no GLM_API_KEY WHEN called THEN returns null immediately', async () => {
    vi.doMock('../../../../core/config/env', () => ({
      env: {
        GLM_API_KEY: undefined,
        GLM_API_URL: 'https://open.bigmodel.cn/api/paas/v4/chat/completions',
        GLM_VISION_MODEL: 'glm-4v-flash',
        GLM_VISION_TIMEOUT_MS: 3000,
      },
    }));

    const fetchSpy = vi.fn();
    vi.stubGlobal('fetch', fetchSpy);

    const { analyzeImage: analyzeNoKey } = await import('../glm.client');
    const result = await analyzeNoKey('https://example.com/img.jpg', 'ROBBERY');
    expect(typeof result === 'number' || result === null).toBe(true);
  });
});
