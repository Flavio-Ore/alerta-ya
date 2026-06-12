import { z } from 'zod';
import { IncidentType, IncidentStatus, Severity } from '@prisma/client';

export const createReportSchema = z.object({
  lat: z.number().min(-90).max(90),
  lng: z.number().min(-180).max(180),
  type: z.nativeEnum(IncidentType),
  formData: z.record(z.unknown()),
  // URLs de evidencia subidas desde el dispositivo (Firebase Storage o GCS)
  // El cliente sube primero, luego manda las URLs aquí
  mediaUrls: z.array(z.string().url()).max(5).default([]),
});

export const listIncidentsQuerySchema = z.object({
  severity: z.nativeEnum(Severity).optional(),
  district: z.string().optional(),
  since: z.string().datetime().optional(),
  // 'ALL' = traer todos los status (panel autoridad). Si se omite → solo ACTIVE no expirados (móvil ciudadano)
  status: z.union([z.nativeEnum(IncidentStatus), z.literal('ALL')]).optional(),
  page: z.coerce.number().int().min(1).default(1),
  pageSize: z.coerce.number().int().min(1).max(100).default(20),
});

export const idParamSchema = z.object({
  id: z.string().min(1, 'ID de incidente requerido'),
});

export const confirmSchema = z.object({
  vote: z.enum(['yes', 'no']),
});

// Solo para autoridades — actualizar estado + mensaje de feedback al ciudadano
export const updateStatusSchema = z.object({
  status: z.nativeEnum(IncidentStatus),
  feedback: z.string().max(200).optional(),
});

// Mini-alert: respuesta del ciudadano al "¿viste algo?"
export const zoneConfirmSchema = z.object({
  zoneKey: z.string().min(1),           // "threshold:-11.980:-77.005:ROBBERY"
  response: z.enum(['yes', 'no']),
});

// Lista de "mis reportes" (ciudadano autenticado)
export const listMyReportsQuerySchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
  pageSize: z.coerce.number().int().min(1).max(100).default(20),
});

// Param para rutas que usan :reportId
export const reportIdParamSchema = z.object({
  // Mismo criterio que idParamSchema — acepta seeds custom además de UUIDs.
  reportId: z.string().min(1),
});

// Body para pedir N upload params para evidencia de un reporte.
// Limitamos a 10 para no abusar de Cloudinary.
export const uploadParamsRequestSchema = z.object({
  count: z.number().int().min(1).max(10),
});

export type ListMyReportsQuery = z.infer<typeof listMyReportsQuerySchema>;
export type CreateReportInput = z.infer<typeof createReportSchema>;
export type ListIncidentsQuery = z.infer<typeof listIncidentsQuerySchema>;
export type ConfirmInput = z.infer<typeof confirmSchema>;
export type UpdateStatusInput = z.infer<typeof updateStatusSchema>;
export type ZoneConfirmInput = z.infer<typeof zoneConfirmSchema>;
