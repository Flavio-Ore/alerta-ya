import { z } from 'zod';

export const registerTokenSchema = z.object({
  // Token FCM generado por Firebase Messaging en el dispositivo
  token: z.string().min(1),
  // Último distrito conocido — se usa para indexar push por zona
  district: z.string().min(1),
  // Lat/Lng opcionales — si se mandan, se calcula el proxTile (~330m) para
  // filtrar push por área específica (confirm-request a testigos cercanos).
  lat: z.number().optional(),
  lng: z.number().optional(),
});

export const deleteTokenSchema = z.object({
  token: z.string().min(1),
});

export type RegisterTokenInput = z.infer<typeof registerTokenSchema>;
export type DeleteTokenInput = z.infer<typeof deleteTokenSchema>;
