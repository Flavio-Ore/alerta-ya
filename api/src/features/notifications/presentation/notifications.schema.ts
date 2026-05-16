import { z } from 'zod';

export const listNotificationsSchema = z.object({
  unreadOnly: z
    .string()
    .optional()
    .transform((v) => v === 'true'),
  page: z.coerce.number().int().min(1).default(1),
  pageSize: z.coerce.number().int().min(1).max(50).default(20),
});

export const markReadSchema = z.object({
  // Array de IDs a marcar como leídas — si está vacío y all=true, marca todas
  ids: z.array(z.string().uuid()).default([]),
  all: z.boolean().default(false),
});

export type ListNotificationsQuery = z.infer<typeof listNotificationsSchema>;
export type MarkReadInput = z.infer<typeof markReadSchema>;
