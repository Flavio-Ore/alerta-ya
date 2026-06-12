import { IncidentType, IncidentStatus, Severity } from '@prisma/client';

import {
  ReportRepository,
  ReportWithIncident,
} from '../repositories/report.repository';

export interface GetMyReportsInput {
  userId: string;
  page: number;
  pageSize: number;
}

export interface MyReportIncidentDTO {
  id: string;
  status: IncidentStatus;
  severity: Severity;
  district: string;
  confirmCount: number;
  denyCount: number;
  reportCount: number;
  expiresAt: string;
  feedback: string | null;
  updatedAt: string;
}

export interface MyReportDTO {
  reportId: string;
  type: IncidentType;
  createdAt: string;
  lat: number;
  lng: number;
  formData: Record<string, unknown>;
  mediaUrls: string[];
  incident: MyReportIncidentDTO | null;
}

export interface GetMyReportsResult {
  items: MyReportDTO[];
  page: number;
  pageSize: number;
  total: number;
}

function projectFormData(
  raw: unknown,
): { formData: Record<string, unknown>; type: IncidentType | null } {
  if (!raw || typeof raw !== 'object') {
    return { formData: {}, type: null };
  }
  const source = raw as Record<string, unknown>;
  const rest: Record<string, unknown> = {};
  let type: IncidentType | null = null;
  for (const [key, value] of Object.entries(source)) {
    if (key === '_type') {
      if (typeof value === 'string') type = value as IncidentType;
      continue;
    }
    rest[key] = value;
  }
  return { formData: rest, type };
}

function toDTO(report: ReportWithIncident): MyReportDTO {
  const { formData, type: formType } = projectFormData(report.formData);
  // Si el reporte ya fue agregado a un incidente, usamos su tipo.
  // Si está huérfano (incident === null) usamos el _type guardado en formData.
  const reportType: IncidentType =
    report.incident?.type ?? formType ?? ('ROBBERY' as IncidentType);

  return {
    reportId: report.id,
    type: reportType,
    createdAt: report.createdAt.toISOString(),
    lat: report.lat,
    lng: report.lng,
    formData,
    mediaUrls: report.mediaUrls,
    incident: report.incident
      ? {
          id: report.incident.id,
          status: report.incident.status,
          severity: report.incident.severity,
          district: report.incident.district,
          confirmCount: report.incident.confirmCount,
          denyCount: report.incident.denyCount,
          reportCount: report.incident.reportCount,
          expiresAt: report.incident.expiresAt.toISOString(),
          feedback: report.incident.feedback,
          updatedAt: report.incident.updatedAt.toISOString(),
        }
      : null,
  };
}

export async function getMyReports(
  input: GetMyReportsInput,
  reportRepo: ReportRepository,
): Promise<GetMyReportsResult> {
  const { items, total } = await reportRepo.findByUserId(input.userId, {
    page: input.page,
    pageSize: input.pageSize,
  });

  return {
    items: items.map(toDTO),
    page: input.page,
    pageSize: input.pageSize,
    total,
  };
}
