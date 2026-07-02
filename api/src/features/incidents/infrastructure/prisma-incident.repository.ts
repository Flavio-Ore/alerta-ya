import { PrismaClient, Incident, IncidentStatusHistory, IncidentType, Severity, IncidentStatus } from '@prisma/client';

import {
  IncidentRepository,
  CreateIncidentData,
  CreateStatusHistoryData,
  IncidentFilters,
  PaginatedIncidents,
} from '../domain/repositories/incident.repository';
import { bucketCoord } from '../../../core/utils/geo.utils';
import { cappedExtendedExpiry } from '../domain/incident-lifecycle';

const BUCKET_TOLERANCE = 0.001; // ~100m

export class PrismaIncidentRepository implements IncidentRepository {
  constructor(private readonly prisma: PrismaClient) {}

  async findActive(filters: IncidentFilters): Promise<PaginatedIncidents> {
    const page = filters.page ?? 1;
    const pageSize = filters.pageSize ?? 20;
    const skip = (page - 1) * pageSize;
    const now = new Date();

    // Status filter — comportamiento según valor:
    //   - 'ALL'      → trae todos los status, sin filtro de expiración (panel autoridad)
    //   - <enum>     → filtra por ese status exacto, sin filtro de expiración
    //   - undefined  → default app móvil. El ciudadano ve incidentes vivos:
    //                  ACTIVE solo si no expiró (el timer auto-cierra reportes
    //                  no atendidos), e IN_ATTENTION siempre — si una autoridad
    //                  lo está atendiendo es relevante hasta que pase a CLOSED.
    const statusWhere =
      filters.status === 'ALL'
        ? {}
        : filters.status
          ? { status: filters.status }
          : {
              OR: [
                { status: IncidentStatus.ACTIVE, expiresAt: { gt: now } },
                { status: IncidentStatus.IN_ATTENTION },
              ],
            };

    const where = {
      ...statusWhere,
      ...(filters.severity && { severity: filters.severity }),
      ...(filters.district && { district: { contains: filters.district, mode: 'insensitive' as const } }),
      ...(filters.sinceISO && { createdAt: { gte: new Date(filters.sinceISO) } }),
    };

    const [items, total] = await this.prisma.$transaction([
      this.prisma.incident.findMany({ where, skip, take: pageSize, orderBy: { createdAt: 'desc' } }),
      this.prisma.incident.count({ where }),
    ]);

    return { items, total, page };
  }

  async findById(id: string): Promise<Incident | null> {
    return this.prisma.incident.findUnique({ where: { id } });
  }

  async findActiveInZone(bucketLat: number, bucketLng: number, type: IncidentType): Promise<Incident | null> {
    const now = new Date();
    return this.prisma.incident.findFirst({
      where: {
        type,
        status: IncidentStatus.ACTIVE,
        expiresAt: { gt: now },
        lat: { gte: bucketLat - BUCKET_TOLERANCE, lte: bucketLat + BUCKET_TOLERANCE },
        lng: { gte: bucketLng - BUCKET_TOLERANCE, lte: bucketLng + BUCKET_TOLERANCE },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async create(data: CreateIncidentData): Promise<Incident> {
    return this.prisma.incident.create({
      data: {
        type: data.type,
        severity: data.severity,
        status: IncidentStatus.ACTIVE,
        lat: data.lat,
        lng: data.lng,
        district: data.district,
        expiresAt: data.expiresAt,
        reportCount: 1,
        confirmCount: 0,
        denyCount: 0,
        aiScore: data.aiScore ?? null,
        aiVerified: data.aiVerified ?? null,
        photoTakenAt: data.photoTakenAt ?? null,
        photoSource: data.photoSource ?? null,
      },
    });
  }

  async updateSeverity(id: string, severity: Severity): Promise<Incident> {
    return this.prisma.incident.update({ where: { id }, data: { severity } });
  }

  async updateStatus(id: string, status: IncidentStatus, feedback?: string): Promise<Incident> {
    return this.prisma.incident.update({
      where: { id },
      data: { status, ...(feedback !== undefined && { feedback }) },
    });
  }

  async incrementReportCount(id: string): Promise<void> {
    await this.prisma.incident.update({
      where: { id },
      data: { reportCount: { increment: 1 } },
    });
  }

  async linkReport(reportId: string, incidentId: string): Promise<void> {
    await this.prisma.report.update({ where: { id: reportId }, data: { incidentId } });
  }

  async extendExpiry(id: string, extraMinutes: number): Promise<void> {
    const incident = await this.prisma.incident.findUnique({ where: { id } });
    if (!incident) return;

    // Tope duro: un incidente no puede vivir más de MAX_INCIDENT_LIFE_MINUTES
    // desde su creación, sin importar cuántos "sigue ahí" lleguen (anti-manipulación).
    const newExpiry = cappedExtendedExpiry(incident.expiresAt, incident.createdAt, extraMinutes);
    await this.prisma.incident.update({ where: { id }, data: { expiresAt: newExpiry } });
  }

  async incrementConfirm(id: string): Promise<Incident> {
    return this.prisma.incident.update({
      where: { id },
      data: { confirmCount: { increment: 1 } },
    });
  }

  async incrementDeny(id: string): Promise<Incident> {
    return this.prisma.incident.update({
      where: { id },
      data: { denyCount: { increment: 1 } },
    });
  }

  async addStatusHistory(data: CreateStatusHistoryData): Promise<IncidentStatusHistory> {
    return this.prisma.incidentStatusHistory.create({ data });
  }

  async getStatusHistory(incidentId: string): Promise<IncidentStatusHistory[]> {
    return this.prisma.incidentStatusHistory.findMany({
      where: { incidentId },
      orderBy: { changedAt: 'asc' },
    });
  }
}

export function bucketForIncident(lat: number, lng: number): { lat: number; lng: number } {
  return { lat: bucketCoord(lat), lng: bucketCoord(lng) };
}
