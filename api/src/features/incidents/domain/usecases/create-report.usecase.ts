import Redis from 'ioredis';

import { Incident, IncidentType } from '@prisma/client';
import { IncidentRepository } from '../repositories/incident.repository';
import { ReportRepository } from '../repositories/report.repository';
import { ReportFormData } from '../entities/report.entity';
import { PublicIncidentDTO, toPublicDTO } from '../entities/incident.entity';
import { evaluateThreshold } from '../../application/threshold.engine';
import { eventBus, IncidentEvents, ConfirmRequestPayload } from '../../../../core/events/event-bus';
import { AppError } from '../../../../core/errors/AppError';
import { isWithinLima, getDistrict, bucketCoord } from '../../../../core/utils/geo.utils';

export interface CreateReportInput {
  uid: string;
  userId: string;
  lat: number;
  lng: number;
  type: IncidentType;
  formData: ReportFormData;
  mediaUrls: string[];
}

export interface CreateReportDeps {
  incidentRepo: IncidentRepository;
  reportRepo: ReportRepository;
  redis: Redis;
}

const WINDOW_20_MIN_SECONDS = 20 * 60;

export async function createReport(
  input: CreateReportInput,
  deps: CreateReportDeps,
): Promise<PublicIncidentDTO | null> {
  if (!isWithinLima(input.lat, input.lng)) {
    throw new AppError(422, 'El incidente está fuera del área de cobertura de Lima Metropolitana');
  }

  const report = await deps.reportRepo.create({
    userId: input.userId,
    lat: input.lat,
    lng: input.lng,
    type: input.type,
    formData: input.formData,
    mediaUrls: input.mediaUrls,
    incidentId: null,
  });

  const decision = await evaluateThreshold(
    {
      lat: input.lat,
      lng: input.lng,
      type: input.type,
      reportId: report.id,
      formData: input.formData,
      now: Date.now(),
    },
    deps.redis,
  );

  if (!decision.publish) {
    // Primer reporte en la zona → mini-alert a ciudadanos cercanos (~1km)
    // El threshold retorna publish:false solo cuando count === 1
    const district = getDistrict(input.lat, input.lng);
    const payload: ConfirmRequestPayload = {
      zoneLabel: district,
      type: input.type,
      lat: input.lat,
      lng: input.lng,
      reporterUserId: input.userId,
    };
    eventBus.emit(IncidentEvents.CONFIRM_REQUEST, payload);
    return null;
  }

  const bucketLat = bucketCoord(input.lat);
  const bucketLng = bucketCoord(input.lng);
  const district = getDistrict(input.lat, input.lng);
  const expiresAt = new Date(Date.now() + WINDOW_20_MIN_SECONDS * 1000);

  let incident: Incident;
  const existing = await deps.incidentRepo.findActiveInZone(bucketLat, bucketLng, input.type);

  if (existing) {
    // Ya existe un incidente — actualizar severidad si escaló
    if (decision.severity && existing.severity !== decision.severity) {
      incident = await deps.incidentRepo.updateSeverity(existing.id, decision.severity);
    } else {
      incident = existing;
    }

    await deps.incidentRepo.incrementReportCount(incident.id);
    await deps.incidentRepo.linkReport(report.id, incident.id);

    if (decision.extendExpiryMinutes) {
      await deps.incidentRepo.extendExpiry(incident.id, decision.extendExpiryMinutes);
    }

    const dto = toPublicDTO(incident);
    eventBus.emit(IncidentEvents.UPDATED, {
      incident: dto,
      reporterUserId: input.userId,
    });
    return dto;
  }

  // Primer incidente para esta zona+tipo — crear y vincular reportes huérfanos
  incident = await deps.incidentRepo.create({
    type: input.type,
    severity: decision.severity!,
    lat: input.lat,
    lng: input.lng,
    district,
    expiresAt,
  });

  const orphaned = await deps.reportRepo.findOrphanedNearby(
    bucketLat,
    bucketLng,
    input.type,
    WINDOW_20_MIN_SECONDS,
  );

  await Promise.all(orphaned.map((r) => deps.incidentRepo.linkReport(r.id, incident.id)));

  const dto = toPublicDTO(incident);
  eventBus.emit(IncidentEvents.NEW, {
    incident: dto,
    reporterUserId: input.userId,
  });
  return dto;
}
