import { z } from 'zod';

export const riskQuerySchema = z.object({
  lat: z.coerce.number().min(-90).max(90),
  lng: z.coerce.number().min(-180).max(180),
  hour: z.coerce.number().int().min(0).max(23).optional(),
});

export type RiskQuery = z.infer<typeof riskQuerySchema>;

/** GET /risk/predict — predicción ML por ubicación, hora y día de semana. */
export const predictQuerySchema = z.object({
  lat: z.coerce.number().min(-90).max(90),
  lng: z.coerce.number().min(-180).max(180),
  hour: z.coerce.number().int().min(0).max(23).optional(),
  dayOfWeek: z.coerce.number().int().min(0).max(6).optional(),
});

export type PredictQuery = z.infer<typeof predictQuerySchema>;
