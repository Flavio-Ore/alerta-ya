import { Report, IncidentType } from '@prisma/client';

import { ReportFormData } from '../entities/report.entity';

export interface CreateReportData {
  userId: string;
  lat: number;
  lng: number;
  type: IncidentType;
  formData: ReportFormData;
  incidentId?: string | null;
}

export interface ReportRepository {
  create(data: CreateReportData): Promise<Report>;
  findOrphanedNearby(
    bucketLat: number,
    bucketLng: number,
    type: IncidentType,
    windowSeconds: number,
  ): Promise<Report[]>;
  findByIncidentId(incidentId: string): Promise<Report[]>;
}
