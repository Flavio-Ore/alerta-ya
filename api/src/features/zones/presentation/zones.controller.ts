import { Request, Response, NextFunction } from 'express';

import { prisma } from '../../../core/config/prisma';
import { PrismaRiskZoneRepository } from '../infrastructure/prisma-risk-zone.repository';
import { getZoneRisk } from '../domain/usecases/get-zone-risk.usecase';

const riskZoneRepo = new PrismaRiskZoneRepository(prisma);

export async function zoneRisk(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const lat = parseFloat(req.params['lat']!);
    const lng = parseFloat(req.params['lng']!);
    const dto = await getZoneRisk(lat, lng, riskZoneRepo);
    res.json(dto);
  } catch (err) {
    next(err);
  }
}
