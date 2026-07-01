import Redis from 'ioredis';

import { Incident, IncidentType } from '@prisma/client';
import { IncidentRepository } from '../repositories/incident.repository';
import { ReportRepository } from '../repositories/report.repository';
import { ReportFormData } from '../entities/report.entity';
import { PublicIncidentDTO, toPublicDTO } from '../entities/incident.entity';
import { evaluateThreshold } from '../../application/threshold.engine';
import { computeReputationDelta } from '../../application/reputation';
import { eventBus, IncidentEvents, ConfirmRequestPayload } from '../../../../core/events/event-bus';
import { AppError } from '../../../../core/errors/AppError';
import { isWithinLima, getDistrict, bucketCoord } from '../../../../core/utils/geo.utils';
import { env } from '../../../../core/config/env';
import { AI_VERIFIED_THRESHOLD } from '../../infrastructure/ml.client';

export interface CreateReportInput {
  uid: string;
  userId: string;
  lat: number;
  lng: number;
  type: IncidentType;
  formData: ReportFormData;
  mediaUrls: string[];
  photoTakenAt?: Date;
  photoSource?: string;
}

/**
 * Puerto del verificador ML (la implementación vive en infraestructura — ml.client).
 * Inyectado desde el controller para no acoplar el dominio a la infra.
 */
export interface VerifyReportPort {
  (input: {
    reportId: string;
    lat: number;
    lng: number;
    type: IncidentType;
    formData: Record<string, unknown>;
    userReputation: number;
    hasEvidence: boolean;
    photoAgeMinutes: number | null;
  }): Promise<{ score: number; verified: boolean } | null>;
}

export interface CreateReportDeps {
  incidentRepo: IncidentRepository;
  reportRepo: ReportRepository;
  redis: Redis;
  /** Opcional: si no se inyecta, el flujo sigue sin verificación (fail-open). */
  verifyReport?: VerifyReportPort;
  /**
   * Actualiza el reputationScore del usuario sumando `delta`.
   * Fire-and-forget — errores se logean y no bloquean la respuesta.
   * Retorna el nuevo score (útil para tests).
   */
  updateReputation?: (userId: string, delta: number) => Promise<number>;
  /**
   * Envía una notificación push al usuario por reputación.
   * Fire-and-forget — errores se logean y no bloquean la respuesta.
   */
  sendFcmToUser?: (userId: string, title: string, body: string) => Promise<void>;
  /**
   * Resuelve un gs:// path a una URL HTTPS firmada para análisis visual.
   * Fail-open: null si el bucket no está configurado o el path es inválido.
   */
  resolveSignedUrl?: (gsPath: string) => Promise<string | null>;
  /**
   * Analiza la primera imagen del reporte contra el tipo de incidente declarado.
   * Retorna +1.0 (consistente), -1.0 (inconsistente), 0.0 (indeterminado) o null (fail-open).
   */
  analyzeImageForIncident?: (signedUrl: string, type: IncidentType) => Promise<number | null>;
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
      reporterUid: input.uid,
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

  // Señales de evidencia derivadas en servidor (no provienen del cliente)
  const hasEvidence = input.mediaUrls.length > 0;
  const hasMedia = input.mediaUrls.length > 0;
  const photoAgeMinutes = input.photoTakenAt
    ? (Date.now() - input.photoTakenAt.getTime()) / 60_000
    : null;

  // Vision task: resolve signed URL then analyze — gates on media + injected ports
  const visionTask = async (): Promise<number | null> => {
    if (!hasMedia || !deps.resolveSignedUrl || !deps.analyzeImageForIncident) return null;
    const signedUrl = await deps.resolveSignedUrl(input.mediaUrls[0]);
    if (!signedUrl) return null;
    return deps.analyzeImageForIncident(signedUrl, input.type);
  };

  // Verificación ML + visión en paralelo (fail-open independiente en cada rama)
  const [mlSettled, visionSettled] = await Promise.allSettled([
    deps.verifyReport
      ? deps.verifyReport({
          reportId: report.id,
          lat: input.lat,
          lng: input.lng,
          type: input.type,
          formData: input.formData as Record<string, unknown>,
          userReputation: 0.5,
          hasEvidence,
          photoAgeMinutes,
        })
      : Promise.resolve(null),
    visionTask(),
  ]);

  const mlRaw = mlSettled.status === 'fulfilled' ? mlSettled.value : null;
  const visionMatch = visionSettled.status === 'fulfilled' ? visionSettled.value : null;

  // Multiplicador de visión: finalScore = clamp(mlScore * (1 + k * visionMatch), 0, 1)
  // visionMatch null → factor = 1.0 → score identity (sin regresión en fail-open)
  const k = env.VISION_SCORE_K;
  const finalScore =
    mlRaw !== null
      ? Math.min(1, Math.max(0, mlRaw.score * (1 + k * (visionMatch ?? 0))))
      : null;

  // aiVerified se re-deriva siempre desde finalScore (fuente única de verdad)
  const aiVerified = finalScore !== null ? finalScore >= AI_VERIFIED_THRESHOLD : null;

  // Primer incidente para esta zona+tipo — crear y vincular reportes huérfanos
  incident = await deps.incidentRepo.create({
    type: input.type,
    severity: decision.severity!,
    lat: input.lat,
    lng: input.lng,
    district,
    expiresAt,
    aiScore: finalScore,
    aiVerified,
    photoTakenAt: input.photoTakenAt ?? null,
    photoSource: input.photoSource ?? null,
  });

  const orphaned = await deps.reportRepo.findOrphanedNearby(
    bucketLat,
    bucketLng,
    input.type,
    WINDOW_20_MIN_SECONDS,
  );

  await Promise.all(orphaned.map((r) => deps.incidentRepo.linkReport(r.id, incident.id)));

  const dto = toPublicDTO(incident);

  // Calcular y aplicar delta de reputación cuando el pipeline ML emitió veredicto
  if (finalScore !== null) {
    const delta = computeReputationDelta(aiVerified!, hasEvidence);
    dto.reputationDelta = delta;

    const fcmTitle = aiVerified
      ? 'Reporte verificado ✓'
      : 'Reporte marcado como sospechoso';
    const fcmBody = aiVerified
      ? `+${delta} puntos de reputación`
      : `${delta} puntos de reputación`;

    // Fire-and-forget — nunca bloquear la respuesta por estas operaciones secundarias
    if (deps.updateReputation) {
      deps.updateReputation(input.userId, delta).catch((err: unknown) =>
        console.error('[REPUTATION] updateReputation failed:', err),
      );
    }
    if (deps.sendFcmToUser) {
      deps.sendFcmToUser(input.userId, fcmTitle, fcmBody).catch((err: unknown) =>
        console.error('[REPUTATION] sendFcmToUser failed:', err),
      );
    }
  }

  eventBus.emit(IncidentEvents.NEW, {
    incident: dto,
    reporterUserId: input.userId,
  });
  return dto;
}
