import Redis from 'ioredis';

import { PublicIncidentDTO } from '../../../incidents/domain/entities/incident.entity';
import { getTokensForDistrict } from '../../infrastructure/device-token.repository';
import { sendIncidentPush } from '../../infrastructure/fcm.service';
import { reverseGeocode } from '../../infrastructure/geocoding.service';
import { eventBus, IncidentEvents } from '../../../../core/events/event-bus';

export function registerNotificationListener(redis: Redis): void {
  eventBus.on(IncidentEvents.NEW, async (incident: PublicIncidentDTO) => {
    await notifyIncident(incident, redis);
  });

  eventBus.on(IncidentEvents.UPDATED, async (incident: PublicIncidentDTO) => {
    await notifyIncident(incident, redis);
  });
}

async function notifyIncident(incident: PublicIncidentDTO, redis: Redis): Promise<void> {
  if (incident.severity === 'LOW') return;

  try {
    const tokens = await getTokensForDistrict(incident.district, redis);
    if (tokens.length === 0) return;

    // Geocoding en paralelo con los tokens — si falla, el push igual sale sin dirección
    const streetAddress = await reverseGeocode(incident.lat, incident.lng);

    await sendIncidentPush(incident, tokens, redis, streetAddress);
  } catch {
    // Fail open — nunca bloquear el flujo principal
  }
}
