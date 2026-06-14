import { z } from 'zod';
import { IncidentType } from '@prisma/client';

const PERIODS = ['today', 'yesterday', '7d', '30d', '12m', 'all'] as const;

export const statsQuerySchema = z.object({
  period: z.enum(PERIODS).default('30d'),
  district: z.string().optional(),
  type: z.nativeEnum(IncidentType).optional(),
  from: z.string().datetime().optional(),
  to: z.string().datetime().optional(),
});

export type StatsQuery = z.infer<typeof statsQuerySchema>;
