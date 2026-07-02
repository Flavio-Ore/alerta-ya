import { Request, Response, NextFunction } from 'express';

import { redis } from '../config/redis';
import { AppError } from '../errors/AppError';

const MAX_EVIDENCE_REQUESTS = 30;
const TTL_SECONDS = 5 * 60; // 5 minutos

/**
 * Rate limiter para la resolución de evidencia firmada: 30 req / 5 min por cuenta.
 * Evita el abuso/scraping de URLs firmadas. Fail-open si Redis cae.
 * NUNCA loggear el userId real ni las URLs firmadas.
 */
export const evidenceRateLimiterMiddleware = async (
  req: Request,
  _res: Response,
  next: NextFunction,
): Promise<void> => {
  const userId = req.user?.uid;

  if (!userId) {
    return next(new AppError(401, 'No autenticado'));
  }

  const key = `rate:evidence:${userId}`;

  try {
    const count = await redis.incr(key);

    if (count === 1) {
      await redis.expire(key, TTL_SECONDS);
    }

    if (count > MAX_EVIDENCE_REQUESTS) {
      return next(new AppError(429, 'Demasiadas solicitudes de evidencia. Intenta en unos minutos.'));
    }

    next();
  } catch {
    console.error('Evidence rate limiter error — Redis unavailable');
    next();
  }
};
