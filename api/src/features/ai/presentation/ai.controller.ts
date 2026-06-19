import { Request, Response, NextFunction } from 'express';

import {
  analyzeHistoricalData,
  GlmClientError,
  streamHistoricalData,
} from '../../incidents/infrastructure/glm.client';
import { AppError } from '../../../core/errors/AppError';
import type { AnalyzeBody } from './ai.schema';

const AI_ERROR_MESSAGES = {
  not_configured: 'El asistente IA no está configurado',
  timeout: 'La IA tardó demasiado en responder. Intenta nuevamente',
  provider_error: 'El proveedor de IA no pudo responder. Intenta nuevamente',
  empty_response: 'La IA respondió sin contenido. Intenta nuevamente',
} as const;

const AI_ERROR_STATUS_CODES = {
  not_configured: 503,
  timeout: 504,
  provider_error: 502,
  empty_response: 502,
} as const;

// Solo autoridades — chat de análisis IA anclado a la data histórica real.
export async function analyze(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const body = req.body as AnalyzeBody;
    const result = await analyzeHistoricalData(body.question, body.context);

    if (!result.ok) {
      next(
        new AppError(
          AI_ERROR_STATUS_CODES[result.reason],
          AI_ERROR_MESSAGES[result.reason],
        ),
      );
      return;
    }

    res.json({ answer: result.answer });
  } catch (err) {
    next(err);
  }
}

function writeStreamEvent(
  res: Response,
  event: 'delta' | 'done' | 'error',
  payload: object,
): void {
  if (res.writableEnded || res.destroyed) return;
  res.write(`event: ${event}\n`);
  res.write(`data: ${JSON.stringify(payload)}\n\n`);
}

export async function analyzeStream(
  req: Request,
  res: Response,
  _next: NextFunction,
): Promise<void> {
  res.status(200);
  res.setHeader('Content-Type', 'text/event-stream; charset=utf-8');
  res.setHeader('Cache-Control', 'no-cache, no-transform');
  res.setHeader('Connection', 'keep-alive');
  res.setHeader('X-Accel-Buffering', 'no');
  res.flushHeaders();

  const controller = new AbortController();
  req.once('aborted', () => controller.abort());
  res.once('close', () => controller.abort());

  try {
    const body = req.body as AnalyzeBody;
    for await (const content of streamHistoricalData(
      body.question,
      body.context,
      controller.signal,
    )) {
      writeStreamEvent(res, 'delta', { content });
    }
    writeStreamEvent(res, 'done', {});
  } catch (error) {
    const reason =
      error instanceof GlmClientError ? error.reason : 'provider_error';
    writeStreamEvent(res, 'error', { message: AI_ERROR_MESSAGES[reason] });
  } finally {
    if (!res.writableEnded && !res.destroyed) res.end();
  }
}
