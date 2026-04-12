import { Request, Response, NextFunction } from 'express';

import { redis } from '../config/redis';
import { AppError } from '../errors/AppError';

const MAX_REPORTS_PER_HOUR = 3;
const TTL_SECONDS = 3600;

/**
 * Rate limiter para reportes: máximo 3 por hora por cuenta.
 * Implementado con Redis — regla CONSTRAINTS.md.
 * NUNCA loggear el userId real.
 */
export const reportRateLimiterMiddleware = async (
  req: Request,
  _res: Response,
  next: NextFunction,
): Promise<void> => {
  const userId = req.user?.uid;

  if (!userId) {
    return next(new AppError(401, 'No autenticado'));
  }

  const key = `rate:report:${userId}`;

  try {
    const count = await redis.incr(key);

    if (count === 1) {
      await redis.expire(key, TTL_SECONDS);
    }

    if (count > MAX_REPORTS_PER_HOUR) {
      return next(new AppError(429, 'Límite de reportes por hora alcanzado. Máximo 3 reportes por hora.'));
    }

    next();
  } catch {
    // Si Redis falla, no bloquear al usuario pero loggear
    console.error('Rate limiter error — Redis unavailable');
    next();
  }
};
