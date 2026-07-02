import { Report, Incident, IncidentType } from '@prisma/client';

import { ReportFormData } from '../entities/report.entity';

export interface CreateReportData {
  userId: string;
  lat: number;
  lng: number;
  type: IncidentType;
  formData: ReportFormData;
  mediaUrls: string[];
  incidentId?: string | null;
  photoTakenAt?: Date | null;
  photoSource?: string | null;
}

export interface FindByUserIdOptions {
  page: number;
  pageSize: number;
}

export type ReportWithIncident = Report & { incident: Incident | null };

export interface FindByUserIdResult {
  items: ReportWithIncident[];
  total: number;
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
  findByUserId(userId: string, opts: FindByUserIdOptions): Promise<FindByUserIdResult>;
  /** Devuelve los firebaseUid únicos de los reportantes de un incidente */
  findFirebaseUidsByIncidentId(incidentId: string): Promise<string[]>;
  /**
   * Devuelve SOLO los reputationScore de los reportantes de un incidente.
   * No expone userId ni identidad — insumo anónimo para el tier agregado.
   */
  findReporterReputationsByIncidentId(incidentId: string): Promise<number[]>;
  /**
   * Cancela (elimina) un reporte pendiente.
   * Solo si el reporte pertenece a userId y su incidentId es null.
   * Lanza AppError 404 si no existe o no pertenece al usuario.
   * Lanza AppError 409 si el reporte ya fue vinculado a un incidente.
   */
  cancelReport(reportId: string, userId: string): Promise<void>;
}
