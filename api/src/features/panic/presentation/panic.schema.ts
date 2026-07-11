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

export const escrowKeySchema = z.object({
  wrappedKey: z.string().min(1),
  kmsKeyVersion: z.string().min(1),
  algorithm: z.literal('RSA_OAEP_256'),
});

export const registerBlockSchema = z.object({
  blockIndex: z.number().int().min(0),
  storagePath: z.string().startsWith('gs://'),
});
