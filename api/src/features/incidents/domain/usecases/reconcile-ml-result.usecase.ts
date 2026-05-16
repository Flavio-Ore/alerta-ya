import Redis from 'ioredis';
import { PrismaClient } from '@prisma/client';

import { applyMlPenalty } from '../../application/ml-penalty';
import { thresholdKey } from '../../application/threshold.engine';

export interface ReconcileMlInput {
  reportId: string;
  lat: number;
  lng: number;
  type: string;
  score: number;
  verified: boolean;
}

export async function reconcileMlResult(
  input: ReconcileMlInput,
  deps: { redis: Redis; prisma: PrismaClient },
): Promise<void> {
  // Persistir resultado en el reporte
  await deps.prisma.report.update({
    where: { id: input.reportId },
    data: { aiVerified: input.verified, aiScore: input.score },
  });

  if (input.score >= 0.3) return;

  // Marcar como sospechoso en Redis para excluir de futuros cómputos
  await applyMlPenalty(input.reportId, input.score, deps.redis);

  // Decrementar el contador en el hash del threshold engine
  const key = thresholdKey(input.lat, input.lng, input.type);

  await deps.redis.hincrby(key, 'count', -1);
}
