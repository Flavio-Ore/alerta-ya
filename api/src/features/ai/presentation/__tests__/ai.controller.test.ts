import type { NextFunction, Request, Response } from 'express';
import { beforeEach, describe, expect, it, vi } from 'vitest';

import { AppError } from '../../../../core/errors/AppError';

vi.mock('../../../incidents/infrastructure/glm.client', () => ({
  analyzeHistoricalData: vi.fn(),
  streamHistoricalData: vi.fn(),
  GlmClientError: class GlmClientError extends Error {
    constructor(public readonly reason: string) {
      super(reason);
    }
  },
}));

const { analyzeHistoricalData, streamHistoricalData } = await import(
  '../../../incidents/infrastructure/glm.client'
);
const { analyze, analyzeStream } = await import('../ai.controller');

const request = {
  body: {
    question: '¿Qué distrito priorizar?',
    context: { districts: [], types: [] },
  },
} as Request;

describe('analyze controller', () => {
  const json = vi.fn();
  const response = { json } as unknown as Response;
  const next = vi.fn() as NextFunction;

  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('GIVEN respuesta válida WHEN analiza THEN responde el contenido', async () => {
    vi.mocked(analyzeHistoricalData).mockResolvedValue({
      ok: true,
      answer: 'Respuesta IA',
    });

    await analyze(request, response, next);

    expect(json).toHaveBeenCalledWith({ answer: 'Respuesta IA' });
    expect(next).not.toHaveBeenCalled();
  });

  it('GIVEN timeout WHEN analiza THEN entrega AppError 504', async () => {
    vi.mocked(analyzeHistoricalData).mockResolvedValue({
      ok: false,
      reason: 'timeout',
    });

    await analyze(request, response, next);

    const error = vi.mocked(next).mock.calls[0]?.[0];
    expect(error).toBeInstanceOf(AppError);
    expect(error).toMatchObject({
      statusCode: 504,
      message: 'La IA tardó demasiado en responder. Intenta nuevamente',
    });
  });

  it('GIVEN error del proveedor WHEN analiza THEN entrega AppError 502', async () => {
    vi.mocked(analyzeHistoricalData).mockResolvedValue({
      ok: false,
      reason: 'provider_error',
    });

    await analyze(request, response, next);

    expect(vi.mocked(next).mock.calls[0]?.[0]).toMatchObject({
      statusCode: 502,
      message: 'El proveedor de IA no pudo responder. Intenta nuevamente',
    });
  });

  it('GIVEN deltas WHEN analiza en stream THEN escribe eventos SSE', async () => {
    vi.mocked(streamHistoricalData).mockReturnValue(
      (async function* () {
        yield 'Hola ';
        yield '**Lima**';
      })(),
    );
    const write = vi.fn();
    const streamResponse = {
      status: vi.fn().mockReturnThis(),
      setHeader: vi.fn(),
      flushHeaders: vi.fn(),
      once: vi.fn(),
      write,
      end: vi.fn(),
    } as unknown as Response;
    const streamRequest = {
      ...request,
      once: vi.fn(),
    } as unknown as Request;

    await analyzeStream(streamRequest, streamResponse, next);

    expect(write).toHaveBeenCalledWith(
      'data: {"content":"Hola "}\n\n',
    );
    expect(write).toHaveBeenCalledWith(
      'data: {"content":"**Lima**"}\n\n',
    );
    expect(write).toHaveBeenCalledWith('event: done\n');
  });
});
