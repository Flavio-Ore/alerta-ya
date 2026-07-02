import { Report } from '@prisma/client';

import { IncidentRepository } from '../repositories/incident.repository';
import { ReportRepository } from '../repositories/report.repository';
import {
  PublicIncidentDetailDTO,
  ReportEvidenceDTO,
  StatusHistoryEntryDTO,
  toPublicDTO,
} from '../entities/incident.entity';
import { AppError } from '../../../../core/errors/AppError';
import { aggregateReporterTier } from '../../application/reputation-tier';

/**
 * Cuenta reportes que satisfacen una flag de formulario.
 * El mobile manda STRINGS, no booleans — chequeo flexible para retro-compat:
 * - weapon: 'firearm' | 'blade' cuentan
 * - injured: 'yes' cuenta
 * - stillInArea: 'yes' cuenta (sigue ahí; fled_* NO)
 */
function countFormFlag(reports: Report[], flag: string): number {
  return reports.filter((r) => {
    const data = r.formData as Record<string, unknown>;
    const v = data[flag];
    if (v === true) return true;
    if (flag === "weapon") return v === "firearm" || v === "blade";
    if (flag === "injured" || flag === "stillInArea") return v === "yes";
    return false;
  }).length;
}

/**
 * Mapea un reporte a su DTO de evidencia pública.
 * NUNCA incluye userId, firebaseUid ni datos de identidad — solo respuestas del formulario y media.
 * El campo _type se filtra porque es interno (usado para coalescing de orphans).
 */
function toEvidenceDTO(report: Report): ReportEvidenceDTO {
  const raw = report.formData as Record<string, unknown>;
  // Excluir el campo interno _type del formulario expuesto
  const { _type: _, ...publicFormData } = raw;
  return {
    formData: publicFormData,
    mediaUrls: report.mediaUrls as string[],
  };
}

export async function getIncidentById(
  id: string,
  incidentRepo: IncidentRepository,
  reportRepo: ReportRepository,
): Promise<PublicIncidentDetailDTO> {
  const incident = await incidentRepo.findById(id);

  if (!incident) {
    throw new AppError(404, 'Incidente no encontrado');
  }

  const [reports, historyRows, reporterScores] = await Promise.all([
    reportRepo.findByIncidentId(id),
    incidentRepo.getStatusHistory(id),
    reportRepo.findReporterReputationsByIncidentId(id),
  ]);

  const statusHistory: StatusHistoryEntryDTO[] = historyRows.map((h) => ({
    id: h.id,
    status: h.status,
    feedback: h.feedback,
    actorRole: h.actorRole,
    changedAt: h.changedAt.toISOString(),
  }));

  return {
    ...toPublicDTO(incident),
    weaponReports: countFormFlag(reports, 'weapon'),
    injuredReports: countFormFlag(reports, 'injured'),
    stillHereReports: countFormFlag(reports, 'stillInArea'),
    evidence: reports.map(toEvidenceDTO),
    statusHistory,
    reporterTrust: aggregateReporterTier(reporterScores),
  };
}
