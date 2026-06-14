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

export type AdminRole = 'AUTHORITY' | 'ADMIN';

export interface AdminUserDTO {
  uid: string;
  email: string;
  displayName: string | null;
  role: AdminRole | null;
  disabled: boolean;
  createdAt: string;
}

export interface ListAdminUsersResult {
  items: AdminUserDTO[];
  total: number;
  page: number;
}

export interface CreateAdminUserInput {
  email: string;
  password: string;
  displayName: string;
  role: AdminRole;
}

export interface UpdateAdminUserInput {
  displayName?: string;
  role?: AdminRole;
  disabled?: boolean;
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

// ── Stats ─────────────────────────────────────────────────

export type StatsPeriod = 'today' | 'yesterday' | '7d' | '30d' | '12m' | 'all';

export interface StatsQuery {
  period?: StatsPeriod;
  district?: string;
  type?: IncidentType;
  from?: string;
  to?: string;
}

export interface StatsResponse {
  summary: {
    totalIncidents: number;
    activeIncidents: number;
    inAttentionIncidents: number;
    closedIncidents: number;
    criticalIncidents: number;
    totalReports: number;
    totalPanicSessions: number;
    avgConfirmations: number;
    kpis: {
      totalReportes: number;
      completeFormPct: number;
      criticalPct: number;
      aiAccuracyPct: number;
      avgResponseMin: number;
      trend: number;
    };
  };
  byType: { type: IncidentType; count: number }[];
  bySeverity: { severity: Severity; count: number }[];
  byStatus: { status: IncidentStatus; count: number }[];
  byDistrict: { district: string; count: number }[];
  byDay: { date: string; count: number }[];
  byHour: { hour: number; count: number }[];
  byDayHour: { day: number; hour: number; count: number }[];
  byTypeAndSeverity: { type: IncidentType; severity: Severity; count: number }[];
  formAnalysis: {
    weaponType: { label: string; count: number; pct: number }[];
    escapeMethod: { label: string; count: number; pct: number }[];
    stillInZonePct: number;
    avgResponseMin: number;
    topVehicleDistrict: string | null;
  };
  comparison: { current: number; previous: number; percentChange: number } | null;
}
