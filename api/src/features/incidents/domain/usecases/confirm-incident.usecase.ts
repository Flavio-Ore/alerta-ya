import Redis from 'ioredis';

import { IncidentRepository } from '../repositories/incident.repository';
import { PublicIncidentDTO, toPublicDTO } from '../entities/incident.entity';
import { eventBus, IncidentEvents } from '../../../../core/events/event-bus';
import { AppError } from '../../../../core/errors/AppError';
import { IncidentStatus } from '@prisma/client';
import { isWithinVoteRange } from '../vote-policy';

const CLOSE_THRESHOLD = 5; // deny > confirm + N → cerrar incidente

export interface ConfirmIncidentInput {
  incidentId: string;
  uid: string;
  vote: 'yes' | 'no';
  /** GPS del votante — obligatorio para el gate de proximidad (anti-manipulación). */
  lat: number;
  lng: number;
}

export interface ConfirmIncidentDeps {
  incidentRepo: IncidentRepository;
  redis: Redis;
}

export async function confirmIncident(
  input: ConfirmIncidentInput,
  deps: ConfirmIncidentDeps,
): Promise<PublicIncidentDTO> {
  const incident = await deps.incidentRepo.findById(input.incidentId);
  if (!incident) throw new AppError(404, 'Incidente no encontrado');
  if (incident.status !== 'ACTIVE') throw new AppError(409, 'El incidente ya no está activo');

  // Gate de proximidad: solo cuenta el voto de quien está cerca del incidente.
  if (!isWithinVoteRange(input.lat, input.lng, incident.lat, incident.lng)) {
    throw new AppError(403, 'Debes estar cerca del incidente para confirmarlo o descartarlo');
  }

  // Deduplicar: un usuario no puede votar dos veces
  const dedupeKey = `confirm:user:${input.uid}:${input.incidentId}`;
  const ttl = Math.max(0, Math.floor((incident.expiresAt.getTime() - Date.now()) / 1000));
  const alreadyVoted = await deps.redis.set(dedupeKey, '1', 'EX', ttl, 'NX');

  if (alreadyVoted === null) {
    throw new AppError(409, 'Ya registraste tu voto para este incidente');
  }

  let updated = input.vote === 'yes'
    ? await deps.incidentRepo.incrementConfirm(input.incidentId)
    : await deps.incidentRepo.incrementDeny(input.incidentId);

  // Auto-cerrar si la cantidad de rechazos supera ampliamente las confirmaciones
  if (updated.denyCount > updated.confirmCount + CLOSE_THRESHOLD) {
    updated = await deps.incidentRepo.updateStatus(input.incidentId, IncidentStatus.CLOSED);
  }

  const dto = toPublicDTO(updated);
  // No hay reporter aquí (es una confirmación ciudadana, no un reporte nuevo).
  // El evento se emite sin reporterUserId → todos los del distrito reciben push.
  eventBus.emit(IncidentEvents.UPDATED, { incident: dto });
  return dto;
}
