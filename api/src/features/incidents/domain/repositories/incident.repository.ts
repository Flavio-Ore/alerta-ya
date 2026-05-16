import { Incident, IncidentType, Severity, IncidentStatus } from '@prisma/client';

export interface CreateIncidentData {
  type: IncidentType;
  severity: Severity;
  lat: number;
  lng: number;
  district: string;
  expiresAt: Date;
}

export interface IncidentFilters {
  severity?: Severity;
  district?: string;
  sinceISO?: string;
  /**
   * Filtro de status:
   *   - undefined → default app móvil: solo ACTIVE no expirados
   *   - IncidentStatus → filtra por ese status exacto (panel autoridad)
   *   - 'ALL' → trae todos los status sin filtro de expiración (panel autoridad)
   */
  status?: IncidentStatus | 'ALL';
  page?: number;
  pageSize?: number;
}

export interface PaginatedIncidents {
  items: Incident[];
  total: number;
  page: number;
}

export interface IncidentRepository {
  findActive(filters: IncidentFilters): Promise<PaginatedIncidents>;
  findById(id: string): Promise<Incident | null>;
  findActiveInZone(bucketLat: number, bucketLng: number, type: IncidentType): Promise<Incident | null>;
  create(data: CreateIncidentData): Promise<Incident>;
  updateSeverity(id: string, severity: Severity): Promise<Incident>;
  updateStatus(id: string, status: IncidentStatus, feedback?: string): Promise<Incident>;
  incrementReportCount(id: string): Promise<void>;
  linkReport(reportId: string, incidentId: string): Promise<void>;
  extendExpiry(id: string, extraMinutes: number): Promise<void>;
  incrementConfirm(id: string): Promise<Incident>;
  incrementDeny(id: string): Promise<Incident>;
}
