import { IncidentRepository, IncidentFilters } from '../repositories/incident.repository';
import { PublicIncidentDTO, toPublicDTO } from '../entities/incident.entity';

export interface GetIncidentsResult {
  items: PublicIncidentDTO[];
  total: number;
  page: number;
}

export async function getIncidents(
  filters: IncidentFilters,
  incidentRepo: IncidentRepository,
): Promise<GetIncidentsResult> {
  const result = await incidentRepo.findActive(filters);

  return {
    items: result.items.map(toPublicDTO),
    total: result.total,
    page: result.page,
  };
}
