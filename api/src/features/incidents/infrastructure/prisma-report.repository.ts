import { PrismaClient, Report, IncidentType } from '@prisma/client';

import {
  ReportRepository,
  CreateReportData,
  FindByUserIdOptions,
  FindByUserIdResult,
} from '../domain/repositories/report.repository';
import { bucketCoord } from '../../../core/utils/geo.utils';
import { AppError } from '../../../core/errors/AppError';

const BUCKET_TOLERANCE = 0.001;

export class PrismaReportRepository implements ReportRepository {
  constructor(private readonly prisma: PrismaClient) {}

  async create(data: CreateReportData): Promise<Report> {
    // Guardar _type en formData para poder filtrar reportes huérfanos por tipo
    const formDataWithType = { ...(data.formData as object), _type: data.type };

    return this.prisma.report.create({
      data: {
        userId: data.userId,
        lat: data.lat,
        lng: data.lng,
        formData: formDataWithType,
        mediaUrls: data.mediaUrls,
        incidentId: data.incidentId ?? null,
      },
    });
  }

  async findOrphanedNearby(
    bucketLat: number,
    bucketLng: number,
    type: IncidentType,
    windowSeconds: number,
  ): Promise<Report[]> {
    const since = new Date(Date.now() - windowSeconds * 1000);
    const bLat = bucketCoord(bucketLat);
    const bLng = bucketCoord(bucketLng);

    const reports = await this.prisma.report.findMany({
      where: {
        incidentId: null,
        createdAt: { gte: since },
        lat: { gte: bLat - BUCKET_TOLERANCE, lte: bLat + BUCKET_TOLERANCE },
        lng: { gte: bLng - BUCKET_TOLERANCE, lte: bLng + BUCKET_TOLERANCE },
      },
    });

    // Filtrar por tipo usando _type guardado en formData JSONB
    return reports.filter((r) => {
      const fd = r.formData as Record<string, unknown>;
      return fd['_type'] === type;
    });
  }

  async findByIncidentId(incidentId: string): Promise<Report[]> {
    return this.prisma.report.findMany({ where: { incidentId } });
  }

  async findByUserId(userId: string, opts: FindByUserIdOptions): Promise<FindByUserIdResult> {
    const skip = (opts.page - 1) * opts.pageSize;

    const [items, total] = await this.prisma.$transaction([
      this.prisma.report.findMany({
        where: { userId },
        orderBy: { createdAt: 'desc' },
        skip,
        take: opts.pageSize,
        include: { incident: true },
      }),
      this.prisma.report.count({ where: { userId } }),
    ]);

    return { items, total };
  }

  async findFirebaseUidsByIncidentId(incidentId: string): Promise<string[]> {
    const reports = await this.prisma.report.findMany({
      where: { incidentId },
      select: { user: { select: { firebaseUid: true } } },
    });
    const uids = reports.map((r) => r.user.firebaseUid);
    return [...new Set(uids)];
  }

  async findReporterReputationsByIncidentId(incidentId: string): Promise<number[]> {
    const reports = await this.prisma.report.findMany({
      where: { incidentId },
      select: { user: { select: { reputationScore: true } } },
    });
    return reports.map((r) => r.user.reputationScore);
  }

  async cancelReport(reportId: string, userId: string): Promise<void> {
    const report = await this.prisma.report.findUnique({
      where: { id: reportId },
      select: { id: true, userId: true, incidentId: true },
    });

    if (!report || report.userId !== userId) {
      throw new AppError(404, 'Reporte no encontrado');
    }

    if (report.incidentId !== null) {
      throw new AppError(409, 'El reporte ya fue vinculado a un incidente y no puede cancelarse');
    }

    await this.prisma.report.delete({ where: { id: reportId } });
  }
}
