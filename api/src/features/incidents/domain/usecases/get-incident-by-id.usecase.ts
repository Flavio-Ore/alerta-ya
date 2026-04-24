import { Report } from '@prisma/client';

import { IncidentRepository } from '../repositories/incident.repository';
import { ReportRepository } from '../repositories/report.repository';
import { PublicIncidentDetailDTO, toPublicDTO } from '../entities/incident.entity';
import { AppError } from '../../../../core/errors/AppError';

function countFormFlag(reports: Report[], flag: string): number {
  return reports.filter((r) => {
    const data = r.formData as Record<string, unknown>;
    return data[flag] === true;
  }).length;
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
  };
}
