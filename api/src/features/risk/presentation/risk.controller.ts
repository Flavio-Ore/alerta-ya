import { Request, Response, NextFunction } from 'express';

import { getRisk } from '../domain/usecases/get-risk.usecase';
import { getRiskArtifact } from '../infrastructure/risk-artifact.repository';

/**
 * GET /risk?lat&lng&hour — riesgo anónimo agregado de un punto a una hora.
 * hour opcional → hora actual del servidor. 422 fuera de Lima. Fail-open.
 */
export function getRiskForPoint(req: Request, res: Response, next: NextFunction): void {
  try {
    const { lat, lng, hour } = req.query as unknown as { lat: number; lng: number; hour?: number };
    const resolvedHour = typeof hour === 'number' ? hour : new Date().getHours();
    const dto = getRisk(lat, lng, resolvedHour, getRiskArtifact());
    res.json(dto);
  } catch (err) {
    next(err);
  }
}
