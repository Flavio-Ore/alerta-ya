import { PrismaClient, Incident, IncidentType, Severity, IncidentStatus } from '@prisma/client';

import {
  IncidentRepository,
  CreateIncidentData,
  IncidentFilters,
  PaginatedIncidents,
} from '../domain/repositories/incident.repository';
import { bucketCoord } from '../../../core/utils/geo.utils';

const BUCKET_TOLERANCE = 0.001; // ~100m

export class PrismaIncidentRepository implements IncidentRepository {
  constructor(private readonly prisma: PrismaClient) {}

  async findActive(filters: IncidentFilters): Promise<PaginatedIncidents> {
    const page = filters.page ?? 1;
    const pageSize = filters.pageSize ?? 20;
    const skip = (page - 1) * pageSize;
    const now = new Date();

    const where = {
      status: IncidentStatus.ACTIVE,
      expiresAt: { gt: now },
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

    const newExpiry = new Date(incident.expiresAt.getTime() + extraMinutes * 60 * 1000);
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
}

export function bucketForIncident(lat: number, lng: number): { lat: number; lng: number } {
  return { lat: bucketCoord(lat), lng: bucketCoord(lng) };
}
