import { Request, Response, NextFunction } from 'express';

import { prisma } from '../../../core/config/prisma';
import { redis } from '../../../core/config/redis';
import { PrismaIncidentRepository } from '../infrastructure/prisma-incident.repository';
import { PrismaReportRepository } from '../infrastructure/prisma-report.repository';
import { UserLookupService } from '../infrastructure/user-lookup.service';
import { createReport } from '../domain/usecases/create-report.usecase';
import { getIncidents } from '../domain/usecases/get-incidents.usecase';
import { getIncidentById } from '../domain/usecases/get-incident-by-id.usecase';
import { confirmIncident } from '../domain/usecases/confirm-incident.usecase';
import { updateIncidentStatus } from '../domain/usecases/update-incident-status.usecase';
import { getMyReports } from '../domain/usecases/get-my-reports.usecase';
import { PrismaNotificationRepository } from '../../notifications/infrastructure/prisma-notification.repository';
import { verifyReport } from '../infrastructure/ml.client';
import { AppError } from '../../../core/errors/AppError';
import { IncidentType, IncidentStatus } from '@prisma/client';
import { getMessaging } from 'firebase-admin/messaging';
const ZONE_CONFIRM_COOLDOWN = 30 * 60; // 30 minutos entre respuestas por zona

const incidentRepo = new PrismaIncidentRepository(prisma);
const reportRepo = new PrismaReportRepository(prisma);
const notificationRepo = new PrismaNotificationRepository(prisma);
const userLookup = new UserLookupService(prisma);

/**
 * Incrementa reputationScore del usuario usando Prisma atomic increment.
 * Aplica floor en 0: si el score resultaría negativo, lo clampea a 0.
 * Retorna el nuevo score.
 */
async function updateReputation(userId: string, delta: number): Promise<number> {
  // Prisma no expone Math.max nativo — hacemos read-then-write sólo cuando delta es negativo
  // para evitar que el score quede por debajo de 0. Para deltas positivos, increment directo.
  if (delta >= 0) {
    const updated = await prisma.user.update({
      where: { id: userId },
      data: { reputationScore: { increment: delta } },
      select: { reputationScore: true },
    });
    return updated.reputationScore;
  }

  // Para deltas negativos: necesitamos leer el score actual y clampear
  const current = await prisma.user.findUnique({
    where: { id: userId },
    select: { reputationScore: true },
  });
  const currentScore = current?.reputationScore ?? 0;
  const newScore = Math.max(0, currentScore + delta);

  await prisma.user.update({
    where: { id: userId },
    data: { reputationScore: newScore },
  });
  return newScore;
}

/**
 * Envía notificación push al usuario sobre su reputación.
 * Fail-open: si no hay tokens o el envío falla, se logea y se continúa.
 */
async function sendFcmToUser(userId: string, title: string, body: string): Promise<void> {
  const tokens = await prisma.deviceToken.findMany({
    where: { userId },
    select: { token: true },
  });

  if (tokens.length === 0) return;

  const messaging = getMessaging();
  await Promise.all(
    tokens.map((t) =>
      messaging
        .send({
          token: t.token,
          notification: { title, body },
          data: { type: 'reputation-update' },
        })
        .catch((err: unknown) =>
          console.error(`[FCM] send failed for token ${t.token.slice(0, 8)}...:`, err),
        ),
    ),
  );
}

export async function listIncidents(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const query = req.query as {
      severity?: string;
      district?: string;
      since?:    string;
      status?:   string;
      page?:     string;
      pageSize?: string;
    };

    const result = await getIncidents(
      {
        severity: query.severity as Parameters<typeof getIncidents>[0]['severity'],
        district: query.district,
        sinceISO: query.since,
        status:   query.status as Parameters<typeof getIncidents>[0]['status'],
        page:     query.page ? parseInt(query.page, 10) : 1,
        pageSize: query.pageSize ? parseInt(query.pageSize, 10) : 20,
      },
      incidentRepo,
    );

    res.json(result);
  } catch (err) {
    next(err);
  }
}

export async function getIncident(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const dto = await getIncidentById(req.params['id']!, incidentRepo, reportRepo);
    res.json(dto);
  } catch (err) {
    next(err);
  }
}

export async function submitReport(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    if (!req.user?.uid) {
      next(new AppError(401, 'No autenticado'));
      return;
    }

    const user = await userLookup.findOrCreate(req.user.uid);

    const body = req.body as {
      lat: number;
      lng: number;
      type: IncidentType;
      formData: Record<string, unknown>;
      mediaUrls: string[];
      photoTakenAt?: string;
      photoSource?: 'exif' | 'device_clock';
    };

    console.log(
      `[REPORT] 📝 new report uid=${req.user.uid} type=${body.type} lat=${body.lat} lng=${body.lng}`,
    );

    const dto = await createReport(
      {
        uid: req.user.uid,
        userId: user.id,
        lat: body.lat,
        lng: body.lng,
        type: body.type,
        formData: body.formData,
        mediaUrls: body.mediaUrls ?? [],
        photoTakenAt: body.photoTakenAt ? new Date(body.photoTakenAt) : undefined,
        photoSource: body.photoSource,
      },
      { incidentRepo, reportRepo, redis, verifyReport, updateReputation, sendFcmToUser },
    );

    console.log(
      `[REPORT] ${dto ? '✓ publicado como incident' : '⏳ pendiente — primer reporte, esperando confirm'} (${dto ? 'incidentId=' + dto.id : 'no incident'})`,
    );

    res.status(dto ? 201 : 200).json({ incident: dto });
  } catch (err) {
    next(err);
  }
}

export async function respondZoneConfirm(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    if (!req.user?.uid) {
      next(new AppError(401, 'No autenticado'));
      return;
    }

    const { zoneKey, response } = req.body as { zoneKey: string; response: 'yes' | 'no' };

    // Cooldown: un usuario no puede responder la misma zona más de una vez cada 30 min
    const cooldownKey = `zone-confirm:${req.user.uid}:${zoneKey}`;
    const acquired = await redis.set(cooldownKey, '1', 'EX', ZONE_CONFIRM_COOLDOWN, 'NX');
    if (!acquired) {
      res.json({ ok: false, reason: 'cooldown' });
      return;
    }

    // "Sí lo vi" → sumar 0.5 al contador del threshold (peso menor que un reporte completo)
    if (response === 'yes') {
      await redis.hincrbyfloat(zoneKey, 'count', 0.5);
    }

    res.json({ ok: true });
  } catch (err) {
    next(err);
  }
}

export async function patchIncidentStatus(
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> {
  try {
    const { status, feedback } = req.body as { status: IncidentStatus; feedback?: string };

    const dto = await updateIncidentStatus(
      {
        incidentId: req.params['id']!,
        status,
        feedback,
        actorUid: req.user!.uid,
        actorRole: req.user!.role ?? 'AUTHORITY',
      },
      { incidentRepo, reportRepo, notificationRepo },
    );

    res.json(dto);
  } catch (err) {
    next(err);
  }
}

export async function listMyReports(
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

    const query = req.query as { page?: string | number; pageSize?: string | number };
    const page = typeof query.page === 'number' ? query.page : parseInt(String(query.page ?? '1'), 10);
    const pageSize =
      typeof query.pageSize === 'number'
        ? query.pageSize
        : parseInt(String(query.pageSize ?? '20'), 10);

    const result = await getMyReports(
      { userId: user.id, page, pageSize },
      reportRepo,
    );

    res.json(result);
  } catch (err) {
    next(err);
  }
}

export async function cancelReport(
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
    await reportRepo.cancelReport(req.params['reportId']!, user.id);

    res.status(204).end();
  } catch (err) {
    next(err);
  }
}

export async function confirmOrDenyIncident(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    if (!req.user?.uid) {
      next(new AppError(401, 'No autenticado'));
      return;
    }

    const body = req.body as { vote: 'yes' | 'no' };

    const dto = await confirmIncident(
      { incidentId: req.params['id']!, uid: req.user.uid, vote: body.vote },
      { incidentRepo, redis },
    );

    res.json(dto);
  } catch (err) {
    next(err);
  }
}
