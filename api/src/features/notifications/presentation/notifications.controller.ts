import { Request, Response, NextFunction } from 'express';

import { prisma } from '../../../core/config/prisma';
import { AppError } from '../../../core/errors/AppError';
import { UserLookupService } from '../../incidents/infrastructure/user-lookup.service';
import { PrismaNotificationRepository } from '../infrastructure/prisma-notification.repository';

const notificationRepo = new PrismaNotificationRepository(prisma);
const userLookup = new UserLookupService(prisma);

/**
 * GET /notifications
 * Devuelve el historial de notificaciones del usuario autenticado.
 * Alimenta el tab "Alertas" en la app mobile.
 */
export async function listNotifications(
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> {
  try {
    if (!req.user?.uid) {
      next(new AppError(401, 'No autenticado'));
      return;
    }

    const user = await userLookup.findOrCreate(req.user.uid);

    const query = req.query as {
      unreadOnly?: string;
      page?: string;
      pageSize?: string;
    };

    const result = await notificationRepo.findByUser(user.id, {
      unreadOnly: query.unreadOnly === 'true',
      page: query.page ? parseInt(query.page, 10) : 1,
      pageSize: query.pageSize ? parseInt(query.pageSize, 10) : 20,
    });

    res.json(result);
  } catch (err) {
    next(err);
  }
}

/**
 * PATCH /notifications/read
 * Marca notificaciones como leídas.
 * - { ids: [...], all: false } → marca solo las IDs indicadas
 * - { ids: [], all: true }     → marca todas las del usuario
 */
export async function markNotificationsRead(
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> {
  try {
    if (!req.user?.uid) {
      next(new AppError(401, 'No autenticado'));
      return;
    }

    const user = await userLookup.findOrCreate(req.user.uid);
    const { ids, all } = req.body as { ids: string[]; all: boolean };

    let updated = 0;

    if (all) {
      updated = await notificationRepo.markAllAsRead(user.id);
    } else if (ids.length > 0) {
      // El repo filtra por userId internamente — no hay riesgo de marcar notifs ajenas
      updated = await notificationRepo.markAsRead(ids, user.id);
    }

    res.json({ ok: true, updated });
  } catch (err) {
    next(err);
  }
}
