/**
 * Tipos espejo del backend AlertaYa API.
 * Fuente de verdad: api/src/features/*\/domain/entities/ + prisma/schema.prisma
 * Mantener sincronizado manualmente cuando cambien los DTOs del API.
 */

export type IncidentType =
  | 'ROBBERY'
  | 'ACCIDENT'
  | 'HARASSMENT'
  | 'EXTORTION'
  | 'SUSPICIOUS';

export type Severity = 'LOW' | 'MODERATE' | 'CRITICAL';

export type IncidentStatus = 'ACTIVE' | 'IN_ATTENTION' | 'CLOSED';

export interface PublicIncidentDTO {
  id: string;
  type: IncidentType;
  severity: Severity;
  status: IncidentStatus;
  lat: number;
  lng: number;
  district: string;
  confirmCount: number;
  denyCount: number;
  reportCount: number;
  expiresAt: string;
  createdAt: string;
  updatedAt: string;
  unitAssigned?: string | null;
  feedback?: string | null;
}

export interface ReportEvidenceDTO {
  formData: Record<string, unknown>;
  mediaUrls: string[];
}

export interface PublicIncidentDetailDTO extends PublicIncidentDTO {
  weaponReports: number;
  injuredReports: number;
  stillHereReports: number;
  evidence: ReportEvidenceDTO[];
}

export interface ListIncidentsResult {
  items: PublicIncidentDTO[];
  total: number;
  page: number;
}

export interface ListIncidentsQuery {
  severity?: Severity;
  district?: string;
  since?:    string;
  /**
   * Filtro de status:
   *   - undefined → solo ACTIVE no expirados (default app móvil)
   *   - IncidentStatus → solo ese status
   *   - 'ALL' → todos los status (panel autoridad necesita esto para ver histórico)
   */
  status?:   IncidentStatus | 'ALL';
  page?:     number;
  pageSize?: number;
}

export interface UpdateStatusInput {
  status: IncidentStatus;
  feedback?: string;
}

/**
 * Sesión de pánico activa — devuelta por GET /panic/sessions/active.
 * NUNCA contiene userId, nombre ni datos personales del ciudadano.
 */
export interface PanicSessionDTO {
  id: string;
  lat: number;
  lng: number;
  startedAt: string; // ISO
}
