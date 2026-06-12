import { Request, Response, NextFunction } from 'express';

import { prisma } from '../../../core/config/prisma';
import { AppError } from '../../../core/errors/AppError';
import { UpdatePreferencesDto } from './me.schema';

/**
 * GET /me/profile
 *
 * Devuelve datos NO sensibles del usuario autenticado:
 * - reputationScore (gamificación)
 * - memberSince (fecha de alta)
 *
 * SEGURIDAD: No expone userId, firebaseUid, email, nombre ni foto.
 * Nombre y foto quedan en Firebase Auth en el cliente.
 */
export async function getProfile(
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> {
  try {
    if (!req.user?.uid) {
      next(new AppError(401, 'No autenticado'));
      return;
    }

    const user = await prisma.user.findUnique({
      where: { firebaseUid: req.user.uid },
      select: { reputationScore: true, createdAt: true },
    });

    if (!user) {
      next(new AppError(404, 'Usuario no encontrado'));
      return;
    }

    res.json({
      reputationScore: user.reputationScore,
      memberSince: user.createdAt.toISOString(),
    });
  } catch (err) {
    next(err);
  }
}

/**
 * GET /me/preferences
 *
 * Devuelve las preferencias operativas del usuario.
 * Si no existen aún, devuelve defaults sin persistir.
 */
export async function getPreferences(
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> {
  try {
    if (!req.user?.uid) {
      next(new AppError(401, 'No autenticado'));
      return;
    }

    const user = await prisma.user.findUnique({
      where: { firebaseUid: req.user.uid },
      select: {
        id: true,
        preferences: {
          select: {
            alertRadiusMeters: true,
            muteNotifications: true,
            panicRecordAudio: true,
            panicAlarmSound: true,
          },
        },
      },
    });

    if (!user) {
      next(new AppError(404, 'Usuario no encontrado'));
      return;
    }

    // Si no existen preferencias, devolver defaults
    res.json({
      alertRadiusMeters: user.preferences?.alertRadiusMeters ?? 2000,
      muteNotifications: user.preferences?.muteNotifications ?? false,
      panicRecordAudio: user.preferences?.panicRecordAudio ?? true,
      panicAlarmSound: user.preferences?.panicAlarmSound ?? true,
    });
  } catch (err) {
    next(err);
  }
}

/**
 * PATCH /me/preferences
 *
 * Crea o actualiza las preferencias del usuario (upsert).
 * Acepta actualización parcial — solo los campos enviados se modifican.
 */
export async function updatePreferences(
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> {
  try {
    if (!req.user?.uid) {
      next(new AppError(401, 'No autenticado'));
      return;
    }

    const user = await prisma.user.findUnique({
      where: { firebaseUid: req.user.uid },
      select: { id: true },
    });

    if (!user) {
      next(new AppError(404, 'Usuario no encontrado'));
      return;
    }

    const body = req.body as UpdatePreferencesDto;

    const prefs = await prisma.userPreference.upsert({
      where: { userId: user.id },
      create: {
        userId: user.id,
        alertRadiusMeters: body.alertRadiusMeters ?? 2000,
        muteNotifications: body.muteNotifications ?? false,
        panicRecordAudio: body.panicRecordAudio ?? true,
        panicAlarmSound: body.panicAlarmSound ?? true,
      },
      update: {
        ...(body.alertRadiusMeters !== undefined && {
          alertRadiusMeters: body.alertRadiusMeters,
        }),
        ...(body.muteNotifications !== undefined && {
          muteNotifications: body.muteNotifications,
        }),
        ...(body.panicRecordAudio !== undefined && {
          panicRecordAudio: body.panicRecordAudio,
        }),
        ...(body.panicAlarmSound !== undefined && {
          panicAlarmSound: body.panicAlarmSound,
        }),
      },
      select: {
        alertRadiusMeters: true,
        muteNotifications: true,
        panicRecordAudio: true,
        panicAlarmSound: true,
      },
    });

    res.json(prefs);
  } catch (err) {
    next(err);
  }
}
