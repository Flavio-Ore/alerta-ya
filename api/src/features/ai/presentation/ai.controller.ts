import { Request, Response, NextFunction } from 'express';

import { analyzeHistoricalData } from '../../incidents/infrastructure/glm.client';
import { AppError } from '../../../core/errors/AppError';
import type { AnalyzeBody } from './ai.schema';

// Solo autoridades — chat de análisis IA anclado a la data histórica real.
export async function analyze(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const body = req.body as AnalyzeBody;
    const answer = await analyzeHistoricalData(body.question, body.context);

    if (answer === null) {
      next(new AppError(503, 'Asistente IA no disponible'));
      return;
    }

    res.json({ answer });
  } catch (err) {
    next(err);
  }
}
