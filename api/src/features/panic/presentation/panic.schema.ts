import { z } from 'zod';

export const startPanicSchema = z.object({
  lat: z.number().min(-90).max(90),
  lng: z.number().min(-180).max(180),
});

export const stopPanicParamsSchema = z.object({
  id: z.string().uuid(),
});

export const updateLocationSchema = z.object({
  lat: z.number().min(-90).max(90),
  lng: z.number().min(-180).max(180),
});

export type StartPanicInput = z.infer<typeof startPanicSchema>;
