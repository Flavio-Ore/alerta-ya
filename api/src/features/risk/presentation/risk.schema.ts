import { z } from 'zod';

export const riskQuerySchema = z.object({
  lat: z.coerce.number().min(-90).max(90),
  lng: z.coerce.number().min(-180).max(180),
  hour: z.coerce.number().int().min(0).max(23).optional(),
});

export type RiskQuery = z.infer<typeof riskQuerySchema>;
