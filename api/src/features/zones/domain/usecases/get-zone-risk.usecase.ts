import { RiskZone } from '@prisma/client';

import { AppError } from '../../../../core/errors/AppError';
import { isWithinLima } from '../../../../core/utils/geo.utils';

export interface RiskZoneRepository {
  findNearest(lat: number, lng: number, radiusKm: number): Promise<RiskZone | null>;
}

export interface ZoneRiskDTO {
  district: string;
  riskScore: number;
  predictedHour: number;
  updatedAt: string;
}

export async function getZoneRisk(
  lat: number,
  lng: number,
  repo: RiskZoneRepository,
): Promise<ZoneRiskDTO> {
  if (!isWithinLima(lat, lng)) {
    throw new AppError(422, 'Coordenadas fuera del área de Lima Metropolitana');
  }

  const zone = await repo.findNearest(lat, lng, 1);

  if (!zone) {
    return { district: 'Lima Metropolitana', riskScore: 0, predictedHour: 0, updatedAt: new Date().toISOString() };
  }

  return {
    district: zone.district,
    riskScore: zone.riskScore,
    predictedHour: zone.predictedHour,
    updatedAt: zone.updatedAt.toISOString(),
  };
}
