import { PrismaClient, Report, IncidentType } from '@prisma/client';

import { ReportRepository, CreateReportData } from '../domain/repositories/report.repository';
import { bucketCoord } from '../../../core/utils/geo.utils';

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
}
