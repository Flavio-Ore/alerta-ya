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
  updateStatus(id: string, status: IncidentStatus): Promise<Incident>;
  incrementReportCount(id: string): Promise<void>;
  linkReport(reportId: string, incidentId: string): Promise<void>;
  extendExpiry(id: string, extraMinutes: number): Promise<void>;
  incrementConfirm(id: string): Promise<Incident>;
  incrementDeny(id: string): Promise<Incident>;
}
