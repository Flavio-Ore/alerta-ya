import { Request, Response, NextFunction } from 'express';
import Redis from 'ioredis';

import { prisma } from '../../../core/config/prisma';
import { redis } from '../../../core/config/redis';
import { PrismaDeviceTokenRepository } from '../infrastructure/prisma-device-token.repository';
import { UserLookupService } from '../../incidents/infrastructure/user-lookup.service';
import { AppError } from '../../../core/errors/AppError';

const deviceTokenRepo = new PrismaDeviceTokenRepository(prisma);
const userLookup = new UserLookupService(prisma);

const REDIS_DISTRICT_TOKENS_PREFIX = 'zone';

/**
 * POST /auth/device-token
 * Registra o actualiza el token FCM del dispositivo.
 * Se llama justo después del login de Firebase en la app mobile.
 */
export async function registerDeviceToken(
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> {
  try {
    if (!req.user?.uid) {
      next(new AppError(401, 'No autenticado'));
      return;
    }

    const { token, district } = req.body as { token: string; district: string };

    const user = await userLookup.findOrCreate(req.user.uid);

    // Persistir en PostgreSQL — backup ante flush de Redis
    await deviceTokenRepo.upsert({ userId: user.id, token, district });

    // Sincronizar con Redis — índice rápido para push por zona
    // Fail open: si Redis falla el token ya quedó en Postgres
    try {
      await (redis as Redis).sadd(`${REDIS_DISTRICT_TOKENS_PREFIX}:${district}:tokens`, token);
    } catch {
      // Redis es caché — no bloquear el happy path
    }

    res.status(200).json({ ok: true });
  } catch (err) {
    next(err);
  }
}

/**
 * DELETE /auth/device-token
 * Elimina el token FCM al hacer logout.
 * El usuario deja de recibir push notifications.
 */
export async function removeDeviceToken(
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> {
  try {
    if (!req.user?.uid) {
      next(new AppError(401, 'No autenticado'));
      return;
    }

    const { token } = req.body as { token: string };

    await deviceTokenRepo.deleteByToken(token);

    // Limpiar de todos los sets de Redis (no sabemos el distrito actual sin consultar)
    // deleteMany en el repo ya es idempotente — si no existe, no lanza error
    try {
      // Buscar en qué distrito estaba y removerlo
      // Usamos SCAN para no bloquear Redis con KEYS
      const keys = await (redis as Redis).keys(`${REDIS_DISTRICT_TOKENS_PREFIX}:*:tokens`);
      if (keys.length > 0) {
        await Promise.all(keys.map((key) => (redis as Redis).srem(key, token)));
      }
    } catch {
      // Fail open
    }

    res.status(200).json({ ok: true });
  } catch (err) {
    next(err);
  }
}
