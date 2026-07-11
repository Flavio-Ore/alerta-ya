import { Request, Response, NextFunction } from 'express';

import { prisma } from '../../../core/config/prisma';
import { PrismaPanicRepository } from '../infrastructure/prisma-panic.repository';
import { PrismaEscrowKeyRepository } from '../infrastructure/prisma-escrow-key.repository';
import { PrismaRecordingBlockRepository } from '../infrastructure/prisma-recording-block.repository';
import { PrismaKeyAccessAuditRepository } from '../infrastructure/prisma-key-access-audit.repository';
import { UserLookupService } from '../../incidents/infrastructure/user-lookup.service';
import { startPanic } from '../domain/usecases/start-panic.usecase';
import { stopPanic } from '../domain/usecases/stop-panic.usecase';
import { updatePanicLocation } from '../domain/usecases/update-panic-location.usecase';
import { getEscrowPublicKey, unwrapEscrowKey } from '../../../core/config/kms';
import { getSignedUrl } from '../../../core/config/firebase';
import { storeEscrowKey } from '../domain/usecases/store-escrow-key.usecase';
import { registerRecordingBlock } from '../domain/usecases/register-recording-block.usecase';
import { releaseRecordingKey } from '../domain/usecases/release-recording-key.usecase';
import { AppError } from '../../../core/errors/AppError';
import { eventBus, PanicEvents } from '../../../core/events/event-bus';
import { toPanicSummaryDTO } from '../domain/entities/panic-session.entity';

const panicRepo = new PrismaPanicRepository(prisma);
const userLookup = new UserLookupService(prisma);
const escrowKeyRepo = new PrismaEscrowKeyRepository(prisma);
const recordingBlockRepo = new PrismaRecordingBlockRepository(prisma);
const keyAccessAuditRepo = new PrismaKeyAccessAuditRepository(prisma);

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
      { panicRepo },
    );

    res.status(201).json(dto);

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

export async function updatePanicLocationHandler(
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> {
  try {
    if (!req.user?.uid) {
      next(new AppError(401, 'No autenticado'));
      return;
    }

    const body = req.body as { lat: number; lng: number };

    await updatePanicLocation(
      { sessionId: req.params['id']!, uid: req.user.uid, lat: body.lat, lng: body.lng },
      {
        panicRepo,
        getUserId: async (uid) => {
          const user = await userLookup.findOrCreate(uid);
          return user.id;
        },
      },
    );

    res.status(204).end();
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

export async function getPanicSessionsHandler(
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> {
  try {
    const hasAuthorityRole = req.user?.role === 'AUTHORITY' || req.user?.role === 'ADMIN';
    const hasLegacyAuthority = req.user?.authority === true;
    if (!hasAuthorityRole && !hasLegacyAuthority) {
      next(new AppError(403, 'Acceso restringido a autoridades'));
      return;
    }

    const query = req.query as unknown as { page: number; pageSize: number; status?: 'ACTIVE' | 'DEACTIVATED' | 'TIMEOUT' };
    const { items, total } = await panicRepo.findAllPaginated(query);

    res.json({ items: items.map(toPanicSummaryDTO), total });
  } catch (err) {
    next(err);
  }
}

export async function getPanicSessionDetailHandler(
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> {
  try {
    const hasAuthorityRole = req.user?.role === 'AUTHORITY' || req.user?.role === 'ADMIN';
    const hasLegacyAuthority = req.user?.authority === true;
    if (!hasAuthorityRole && !hasLegacyAuthority) {
      next(new AppError(403, 'Acceso restringido a autoridades'));
      return;
    }

    const session = await panicRepo.findByIdWithCount(req.params['id']!);
    if (!session) {
      next(new AppError(404, 'Sesión no encontrada'));
      return;
    }

    res.json(toPanicSummaryDTO(session));
  } catch (err) {
    next(err);
  }
}

export async function getEscrowPublicKeyHandler(
  _req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> {
  try {
    const { publicKeyPem, keyVersion } = await getEscrowPublicKey();
    res.json({ publicKeyPem, kmsKeyVersion: keyVersion });
  } catch (err) {
    next(err);
  }
}

export async function submitEscrowKeyHandler(
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> {
  try {
    if (!req.user?.uid) {
      next(new AppError(401, 'No autenticado'));
      return;
    }
    const body = req.body as { wrappedKey: string; kmsKeyVersion: string; algorithm: string };
    await storeEscrowKey(
      { panicSessionId: req.params['id']!, uid: req.user.uid, ...body },
      {
        panicRepo,
        escrowRepo: escrowKeyRepo,
        getUserId: async (uid) => (await userLookup.findOrCreate(uid)).id,
      },
    );
    res.status(201).end();
  } catch (err) {
    next(err);
  }
}

export async function registerBlockHandler(
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> {
  try {
    if (!req.user?.uid) {
      next(new AppError(401, 'No autenticado'));
      return;
    }
    const body = req.body as { blockIndex: number; storagePath: string };
    await registerRecordingBlock(
      { panicSessionId: req.params['id']!, uid: req.user.uid, ...body },
      {
        panicRepo,
        blockRepo: recordingBlockRepo,
        getUserId: async (uid) => (await userLookup.findOrCreate(uid)).id,
      },
    );
    res.status(201).end();
  } catch (err) {
    next(err);
  }
}

export async function releaseRecordingKeyHandler(
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> {
  try {
    if (!req.user?.uid) {
      next(new AppError(401, 'No autenticado'));
      return;
    }
    const requester = await userLookup.findOrCreate(req.user.uid);

    const hasAuthorityRole = req.user.role === 'AUTHORITY' || req.user.role === 'ADMIN';
    const hasLegacyAuthority = req.user.authority === true;
    if (!hasAuthorityRole && !hasLegacyAuthority) {
      await keyAccessAuditRepo.create({
        panicSessionId: req.params['id']!,
        requestedById: requester.id,
        ipAddress: req.ip ?? null,
        result: 'DENIED',
      });
      next(new AppError(403, 'Acceso restringido a autoridades'));
      return;
    }

    const result = await releaseRecordingKey(
      {
        panicSessionId: req.params['id']!,
        requestedById: requester.id,
        ipAddress: req.ip ?? null,
      },
      {
        escrowRepo: escrowKeyRepo,
        blockRepo: recordingBlockRepo,
        auditRepo: keyAccessAuditRepo,
        unwrapKey: unwrapEscrowKey,
        getSignedUrl,
      },
    );
    res.json(result);
  } catch (err) {
    next(err);
  }
}
