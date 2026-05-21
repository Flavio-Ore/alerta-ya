import { Request, Response, NextFunction } from 'express';

import { prisma } from '../../../core/config/prisma';
import { PrismaPanicRepository } from '../infrastructure/prisma-panic.repository';
import { UserLookupService } from '../../incidents/infrastructure/user-lookup.service';
import { startPanic } from '../domain/usecases/start-panic.usecase';
import { stopPanic } from '../domain/usecases/stop-panic.usecase';
import { generateSignedUrls } from '../infrastructure/gcs.client';
import { AppError } from '../../../core/errors/AppError';

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
      { panicRepo, generateUploadUrls: generateSignedUrls },
    );

    res.status(201).json(dto);
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
  } catch (err) {
    next(err);
  }
}
