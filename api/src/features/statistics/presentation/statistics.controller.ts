import { Request, Response, NextFunction } from 'express';

import { prisma } from '../../../core/config/prisma';
import { getStats } from '../domain/usecases/get-stats.usecase';
import type { StatsQuery } from './statistics.schema';

export async function handleGetStats(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const query = req.query as unknown as StatsQuery;
    const result = await getStats(query, prisma);
    res.json(result);
  } catch (err) {
    next(err);
  }
}
