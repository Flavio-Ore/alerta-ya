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
}

export interface ReportEvidenceDTO {
  /** Respuestas del formulario — sin userId ni datos de identidad */
  formData: Record<string, unknown>;
  /** URLs de media subidas por el reportante (Firebase Storage / GCS) */
  mediaUrls: string[];
}

export interface PublicIncidentDetailDTO extends PublicIncidentDTO {
  weaponReports: number;
  injuredReports: number;
  stillHereReports: number;
  /** Evidencia agregada por reporte — nunca expone userId ni firebaseUid */
  evidence: ReportEvidenceDTO[];
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
  };
}
