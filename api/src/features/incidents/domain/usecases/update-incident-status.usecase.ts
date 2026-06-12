import { IncidentStatus } from '@prisma/client';

import { IncidentRepository } from '../repositories/incident.repository';
import { ReportRepository } from '../repositories/report.repository';
import { NotificationRepository } from '../../../notifications/domain/repositories/notification.repository';
import { PublicIncidentDTO, toPublicDTO } from '../entities/incident.entity';
import { AppError } from '../../../../core/errors/AppError';
import {
  eventBus,
  IncidentEvents,
  StatusChangedForReportersPayload,
} from '../../../../core/events/event-bus';

export interface UpdateIncidentStatusInput {
  incidentId: string;
  status: IncidentStatus;
  /** Mensaje opcional de la autoridad — máximo 200 caracteres */
  feedback?: string;
}

export interface UpdateIncidentStatusDeps {
  incidentRepo: IncidentRepository;
  reportRepo: ReportRepository;
  notificationRepo: NotificationRepository;
}

const STATUS_LABELS: Record<IncidentStatus, string> = {
  ACTIVE: 'activo',
  IN_ATTENTION: 'siendo atendido',
  CLOSED: 'cerrado',
};

export async function updateIncidentStatus(
  input: UpdateIncidentStatusInput,
  deps: UpdateIncidentStatusDeps,
): Promise<PublicIncidentDTO> {
  const incident = await deps.incidentRepo.findById(input.incidentId);

  if (!incident) {
    throw new AppError(404, 'Incidente no encontrado');
  }

  if (incident.status === IncidentStatus.CLOSED) {
    throw new AppError(409, 'El incidente ya está cerrado');
  }

  // Actualizar estado + feedback en Postgres
  const updated = await deps.incidentRepo.updateStatus(
    input.incidentId,
    input.status,
    input.feedback,
  );

  const dto = toPublicDTO(updated);

  // Emitir por WebSocket — el mapa actualiza el color del pin en tiempo real
  eventBus.emit(IncidentEvents.UPDATED, dto);

  // Emitir evento dirigido a los reportantes — "Mis reportes" se actualiza en vivo
  // Fail open — si falla no bloquea la respuesta a la autoridad
  try {
    const firebaseUids = await deps.reportRepo.findFirebaseUidsByIncidentId(
      input.incidentId,
    );
    if (firebaseUids.length > 0) {
      const payload: StatusChangedForReportersPayload = {
        firebaseUids,
        incidentId: updated.id,
        status: updated.status,
        feedback: updated.feedback,
        district: updated.district,
        type: updated.type,
        updatedAt: updated.updatedAt.toISOString(),
      };
      eventBus.emit(IncidentEvents.STATUS_CHANGED_FOR_REPORTERS, payload);
    }
  } catch {
    // Fail open
  }

  // Notificar a cada usuario que reportó este incidente
  // Fail open — si falla no bloquea la respuesta a la autoridad
  try {
    const reports = await deps.reportRepo.findByIncidentId(input.incidentId);
    const uniqueUserIds = [...new Set(reports.map((r) => r.userId))];

    const statusLabel = STATUS_LABELS[input.status];
    const title = `Tu reporte está ${statusLabel}`;
    const body = input.feedback
      ? `Incidente en ${incident.district} — "${input.feedback}"`
      : `El incidente en ${incident.district} está ${statusLabel}`;

    await Promise.allSettled(
      uniqueUserIds.map((userId) =>
        deps.notificationRepo.create({
          userId,
          type: 'INCIDENT_STATUS_UPDATE',
          title,
          body,
          incidentId: input.incidentId,
        }),
      ),
    );
  } catch {
    // Fail open — la actualización del estado ya se guardó
  }

  return dto;
}
