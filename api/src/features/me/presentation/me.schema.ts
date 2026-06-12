import { z } from 'zod';

/**
 * PATCH /me/preferences — actualiza preferencias del ciudadano.
 * Solo campos operativos, sin PII.
 */
export const updatePreferencesSchema = z.object({
  alertRadiusMeters: z
    .number()
    .int()
    .min(500, 'Mínimo 500 m')
    .max(10000, 'Máximo 10 km')
    .optional(),
  muteNotifications: z.boolean().optional(),
  panicRecordAudio: z.boolean().optional(),
  panicAlarmSound: z.boolean().optional(),
});

export type UpdatePreferencesDto = z.infer<typeof updatePreferencesSchema>;
