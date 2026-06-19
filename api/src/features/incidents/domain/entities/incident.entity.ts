import {
  Incident,
  IncidentType,
  Severity,
  IncidentStatus,
} from "@prisma/client";

export { IncidentType, Severity, IncidentStatus };

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
  /** Mensaje de la autoridad visible al ciudadano al atender el incidente */
  feedback?: string | null;
  /** Confianza del verificador ML (0–1) — null si la IA no corrió */
  aiScore?: number | null;
  /** true si el reporte pasó el verificador ML */
  aiVerified?: boolean | null;
}

export interface ReportEvidenceDTO {
  /** Respuestas del formulario — sin userId ni datos de identidad */
  formData: Record<string, unknown>;
  /** URLs de media subidas por el reportante (Firebase Storage / GCS) */
  mediaUrls: string[];
}

export interface StatusHistoryEntryDTO {
  id: string;
  status: IncidentStatus;
  feedback: string | null;
  actorRole: string;
  changedAt: string; // ISO
}

export interface PublicIncidentDetailDTO extends PublicIncidentDTO {
  weaponReports: number;
  injuredReports: number;
  stillHereReports: number;
  /** Evidencia agregada por reporte — nunca expone userId ni firebaseUid */
  evidence: ReportEvidenceDTO[];
  /** Historial de cambios de estado — auditoría visible para autoridades */
  statusHistory: StatusHistoryEntryDTO[];
}

export function toPublicDTO(incident: Incident): PublicIncidentDTO {
  return {
    id: incident.id,
    type: incident.type,
    severity: incident.severity,
    status: incident.status,
    lat: incident.lat,
    lng: incident.lng,
    district: incident.district,
    confirmCount: incident.confirmCount,
    denyCount: incident.denyCount,
    reportCount: incident.reportCount,
    expiresAt: incident.expiresAt.toISOString(),
    createdAt: incident.createdAt.toISOString(),
    updatedAt: incident.updatedAt.toISOString(),
    unitAssigned: incident.unitAssigned,
    feedback: incident.feedback,
    aiScore: incident.aiScore,
    aiVerified: incident.aiVerified,
  };
}
