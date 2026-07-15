import Redis from 'ioredis';

import { PrismaDeviceTokenRepository } from '../../../auth/infrastructure/prisma-device-token.repository';
import { PrismaNotificationRepository } from '../../infrastructure/prisma-notification.repository';
import { sendIncidentPush } from '../../infrastructure/fcm.service';
import { reverseGeocode } from '../../infrastructure/geocoding.service';
import {
  eventBus,
  IncidentEvents,
  IncidentEventPayload,
} from '../../../../core/events/event-bus';
import { prisma } from '../../../../core/config/prisma';
import { NotificationType } from '@prisma/client';

const deviceTokenRepo = new PrismaDeviceTokenRepository(prisma);
const notificationRepo = new PrismaNotificationRepository(prisma);

export function registerNotificationListener(redis: Redis): void {
  eventBus.on(IncidentEvents.NEW, async (payload: IncidentEventPayload) => {
    await notifyIncident(payload, redis, 'INCIDENT_NEW');
  });

  eventBus.on(IncidentEvents.UPDATED, async (payload: IncidentEventPayload) => {
    await notifyIncident(payload, redis, 'INCIDENT_UPDATED');
  });
}

async function notifyIncident(
  payload: IncidentEventPayload,
  redis: Redis,
  notifType: NotificationType,
): Promise<void> {
  const { incident, reporterUserId } = payload;
  // Solo notificar MODERATE y CRITICAL — LOW no genera push (CONSTRAINTS.md)
  if (incident.severity === 'LOW') return;

  try {
    // 1. Obtener tokens + userIds desde Postgres (fuente de verdad)
    //    Fallback a Redis si la DB falla — fail open siempre
    let entries: { token: string; userId: string }[] = [];
    try {
      entries = await deviceTokenRepo.findByDistrictWithUserId(incident.district);
    } catch {
      // DB no disponible — intentar Redis como fallback
      const redisTokens = await redis.smembers(`zone:${incident.district}:tokens`);
      // Sin userId disponible desde Redis — enviar FCM pero no persistir notificación
      if (redisTokens.length > 0) {
        const streetAddress = await reverseGeocode(incident.lat, incident.lng).catch(() => null);
        await sendIncidentPush(incident, redisTokens, redis, streetAddress);
      }
      return;
    }

    // EXCLUIR al reportante — no se notifica a sí mismo de su propio reporte.
    if (reporterUserId) {
      entries = entries.filter((e) => e.userId !== reporterUserId);
    }

    if (entries.length === 0) return;

    // 2. Geocoding en paralelo — si falla, el push sale igual sin dirección exacta
    const streetAddress = await reverseGeocode(incident.lat, incident.lng).catch(() => null);

    const location = streetAddress
      ? `${streetAddress}, ${incident.district}`
      : incident.district;
    const title = 'AlertaYa | Alerta en tu zona';
    const body = `${incident.type} en ${location} — ${incident.reportCount} reportes`;

    // 3. Persistir notificación en DB por cada usuario único ANTES de enviar FCM
    //    El tab "Alertas" muestra lo que está en DB — FCM es solo el delivery en tiempo real.
    //    Si FCM falla, el usuario igual ve la notificación al abrir la app.
    const uniqueUserIds = [...new Set(entries.map((e) => e.userId))];
    await Promise.allSettled(
      uniqueUserIds.map((userId) =>
        notificationRepo.create({
          userId,
          type: notifType,
          title,
          body,
          incidentId: incident.id,
        }),
      ),
    );

    // 4. Enviar push FCM a los tokens elegibles (con cooldown por token)
    const tokens = entries.map((e) => e.token);
    await sendIncidentPush(incident, tokens, redis, streetAddress);
  } catch {
    // Fail open — nunca bloquear el flujo principal de reporte
  }
}
