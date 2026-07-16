import { Request, Response, NextFunction } from 'express';

import { prisma } from '../../../core/config/prisma';
import { getRisk } from '../domain/usecases/get-risk.usecase';
import { getLiveRiskArtifact } from '../infrastructure/live-risk.repository';

/**
 * GET /risk?lat&lng&hour — riesgo anónimo agregado de un punto a una hora.
 * hour opcional → hora actual del servidor. 422 fuera de Lima. Fail-open.
 *
 * El artefacto es seed + incidentes reales, invalidado por watermark: si nadie
 * reportó desde el último cálculo, sirve cache. Si la BD falla, getLiveRiskArtifact
 * cae al artefacto horneado — la pantalla nunca queda sin datos por culpa de Cloud SQL.
 */
export async function getRiskForPoint(
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> {
  try {
    const { lat, lng, hour } = req.query as unknown as { lat: number; lng: number; hour?: number };
    const resolvedHour = typeof hour === 'number' ? hour : new Date().getHours();
    const artifact = await getLiveRiskArtifact(prisma);
    const dto = getRisk(lat, lng, resolvedHour, artifact);
    res.json(dto);
  } catch (err) {
    next(err);
  }
}
