import { Request, Response, NextFunction } from 'express';

import { prisma } from '../../../core/config/prisma';
import { isWithinLima } from '../../../core/utils/geo.utils';
import { AppError } from '../../../core/errors/AppError';
import { getRisk } from '../domain/usecases/get-risk.usecase';
import { getLiveRiskArtifact } from '../infrastructure/live-risk.repository';
import { predictRisk } from '../infrastructure/predict.client';

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

/**
 * GET /risk/predict?lat&lng&hour&dayOfWeek — predicción del modelo ML (XGBoost
 * Poisson). A diferencia de /risk (determinístico), este distingue día de semana.
 * hour/dayOfWeek opcionales → momento actual del servidor. 422 fuera de Lima.
 *
 * Fail-open: si el ML service no responde o el modelo está degradado, retorna
 * `available: false` con 200 — la UI muestra "predicción no disponible" sin romper.
 */
export async function getRiskPrediction(
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> {
  try {
    const { lat, lng, hour, dayOfWeek } = req.query as unknown as {
      lat: number;
      lng: number;
      hour?: number;
      dayOfWeek?: number;
    };
    if (!isWithinLima(lat, lng)) {
      throw new AppError(422, 'Coordenadas fuera del área de Lima Metropolitana');
    }
    const now = new Date();
    const resolvedHour = typeof hour === 'number' ? hour : now.getHours();
    // JS getDay(): 0=domingo..6=sábado. El modelo usa 0=lunes..6=domingo.
    const resolvedDow = typeof dayOfWeek === 'number' ? dayOfWeek : (now.getDay() + 6) % 7;

    const prediction = await predictRisk({ lat, lng, hour: resolvedHour, dayOfWeek: resolvedDow });

    if (!prediction) {
      res.json({ available: false, hour: resolvedHour, dayOfWeek: resolvedDow });
      return;
    }
    res.json({ available: true, ...prediction });
  } catch (err) {
    next(err);
  }
}
