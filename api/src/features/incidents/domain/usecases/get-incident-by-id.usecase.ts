import { Report } from '@prisma/client';

import { IncidentRepository } from '../repositories/incident.repository';
import { ReportRepository } from '../repositories/report.repository';
import {
  PublicIncidentDetailDTO,
  ReportEvidenceDTO,
  toPublicDTO,
} from '../entities/incident.entity';
import { AppError } from '../../../../core/errors/AppError';

function countFormFlag(reports: Report[], flag: string): number {
  return reports.filter((r) => {
    const data = r.formData as Record<string, unknown>;
    return data[flag] === true;
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

  const reports = await reportRepo.findByIncidentId(id);

  return {
    ...toPublicDTO(incident),
    weaponReports: countFormFlag(reports, 'weapon'),
    injuredReports: countFormFlag(reports, 'injured'),
    stillHereReports: countFormFlag(reports, 'stillInArea'),
    evidence: reports.map(toEvidenceDTO),
  };
}
