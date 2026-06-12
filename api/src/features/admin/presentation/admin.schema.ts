import { z } from 'zod';

export const ROLES = ['AUTHORITY', 'ADMIN'] as const;

export const createUserSchema = z.object({
  email: z.string().email('Correo inválido'),
  password: z.string().min(6, 'La contraseña debe tener al menos 6 caracteres'),
  displayName: z.string().min(1, 'El nombre es requerido'),
  role: z.enum(ROLES),
});

export const updateUserSchema = z.object({
  displayName: z.string().min(1).optional(),
  role: z.enum(ROLES).optional(),
  disabled: z.boolean().optional(),
});

export const listUsersQuerySchema = z.object({
  search: z.string().optional(),
  page: z.coerce.number().int().min(1).default(1),
  pageSize: z.coerce.number().int().min(1).max(100).default(20),
  role: z.enum(ROLES).optional(),
});

export type CreateUserInput = z.infer<typeof createUserSchema>;
export type UpdateUserInput = z.infer<typeof updateUserSchema>;
export type ListUsersQuery = z.infer<typeof listUsersQuerySchema>;
