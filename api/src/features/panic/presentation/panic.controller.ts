import { Request, Response, NextFunction } from 'express';

import { prisma } from '../../../core/config/prisma';
import { PrismaPanicRepository } from '../infrastructure/prisma-panic.repository';
import { UserLookupService } from '../../incidents/infrastructure/user-lookup.service';
import { startPanic } from '../domain/usecases/start-panic.usecase';
import { stopPanic } from '../domain/usecases/stop-panic.usecase';
import { generateCloudinaryUploadParams } from '../infrastructure/cloudinary.client';
import { AppError } from '../../../core/errors/AppError';
import { eventBus, PanicEvents } from '../../../core/events/event-bus';

const panicRepo = new PrismaPanicRepository(prisma);
const userLookup = new UserLookupService(prisma);

export async function startPanicSession(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    if (!req.user?.uid) {
      next(new AppError(401, 'No autenticado'));
      return;
    }

    const user = await userLookup.findOrCreate(req.user.uid);
    const body = req.body as { lat: number; lng: number };

    const dto = await startPanic(
      { userId: user.id, lat: body.lat, lng: body.lng },
      { panicRepo, generateUploadParams: generateCloudinaryUploadParams },
    );

    res.status(201).json(dto);

    // Notificar al panel de autoridades en tiempo real (solo coordenadas — sin PII)
    eventBus.emit(PanicEvents.STARTED, {
      id: dto.id,
      lat: dto.lat,
      lng: dto.lng,
      startedAt: dto.startedAt,
    });
  } catch (err) {
    next(err);
  }
}

export async function stopPanicSession(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    if (!req.user?.uid) {
      next(new AppError(401, 'No autenticado'));
      return;
    }

    const dto = await stopPanic(
      { sessionId: req.params['id']!, uid: req.user.uid },
      { panicRepo, userLookup },
    );

    res.json(dto);

    eventBus.emit(PanicEvents.STOPPED, { id: dto.id });
  } catch (err) {
    next(err);
  }
}

export async function getActivePanicSessions(
  _req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> {
  try {
    const sessions = await panicRepo.findAllActive();
    // Solo coordenadas — nunca exponer userId ni datos del ciudadano (SECURITY_RULES)
    res.json(
      sessions.map((s) => ({
        id: s.id,
        lat: s.lat,
        lng: s.lng,
        startedAt: s.startedAt.toISOString(),
      })),
    );
  } catch (err) {
    next(err);
  }
}
