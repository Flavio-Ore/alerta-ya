import { PrismaClient, RiskZone } from '@prisma/client';

import { RiskZoneRepository } from '../domain/usecases/get-zone-risk.usecase';

export class PrismaRiskZoneRepository implements RiskZoneRepository {
  constructor(private readonly prisma: PrismaClient) {}

  async findNearest(lat: number, lng: number, radiusKm: number): Promise<RiskZone | null> {
    // Pre-filtro por bounding box (~radiusKm en grados)
    const delta = radiusKm / 111; // 1° ≈ 111km
    const zones = await this.prisma.riskZone.findMany({
      where: {
        lat: { gte: lat - delta, lte: lat + delta },
        lng: { gte: lng - delta, lte: lng + delta },
      },
    });

    if (zones.length === 0) return null;

    // Encontrar el más cercano con Haversine simplificado
    let nearest: RiskZone | null = null;
    let minDist = Infinity;

    for (const zone of zones) {
      const dist = haversineKm(lat, lng, zone.lat, zone.lng);
      if (dist < minDist) {
        minDist = dist;
        nearest = zone;
      }
    }

    return nearest;
  }
}

function haversineKm(lat1: number, lng1: number, lat2: number, lng2: number): number {
  const R = 6371;
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLng = ((lng2 - lng1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos((lat1 * Math.PI) / 180) * Math.cos((lat2 * Math.PI) / 180) * Math.sin(dLng / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}
