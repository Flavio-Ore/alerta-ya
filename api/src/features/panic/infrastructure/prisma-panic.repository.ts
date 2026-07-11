import { PrismaClient, PanicSession, PanicStatus } from '@prisma/client';

import {
  PanicSessionRepository,
  CreatePanicSessionData,
  ListPanicSessionsQuery,
  PaginatedPanicSessions,
  PanicSessionWithCount,
} from '../domain/repositories/panic-session.repository';

export class PrismaPanicRepository implements PanicSessionRepository {
  constructor(private readonly prisma: PrismaClient) {}

  async create(data: CreatePanicSessionData): Promise<PanicSession> {
    return this.prisma.panicSession.create({
      data: {
        userId: data.userId,
        lat: data.lat,
        lng: data.lng,
        status: PanicStatus.ACTIVE,
        recordingUrls: [],
      },
    });
  }

  async findActiveByUser(userId: string): Promise<PanicSession | null> {
    return this.prisma.panicSession.findFirst({
      where: { userId, status: PanicStatus.ACTIVE },
    });
  }

  async findAllActive(): Promise<PanicSession[]> {
    // Máximo 2h — las sesiones huérfanas (app crasheada) no quedan pegadas para siempre.
    // El job expire-panic-sessions las marca DEACTIVATED, pero este filtro es el safety net.
    const cutoff = new Date(Date.now() - 2 * 60 * 60 * 1000);
    return this.prisma.panicSession.findMany({
      where: { status: PanicStatus.ACTIVE, startedAt: { gte: cutoff } },
      orderBy: { startedAt: 'desc' },
    });
  }

  async findAllPaginated(query: ListPanicSessionsQuery): Promise<PaginatedPanicSessions> {
    const where = query.status ? { status: query.status } : {};
    const skip = (query.page - 1) * query.pageSize;

    const [items, total] = await Promise.all([
      this.prisma.panicSession.findMany({
        where,
        orderBy: { startedAt: 'desc' },
        skip,
        take: query.pageSize,
        include: { _count: { select: { recordingBlocks: true } } },
      }),
      this.prisma.panicSession.count({ where }),
    ]);

    return { items: items as PanicSessionWithCount[], total };
  }

  async expireOldSessions(olderThanMinutes: number): Promise<number> {
    const cutoff = new Date(Date.now() - olderThanMinutes * 60 * 1000);
    const result = await this.prisma.panicSession.updateMany({
      where: { status: PanicStatus.ACTIVE, startedAt: { lt: cutoff } },
      data: { status: PanicStatus.DEACTIVATED, endedAt: new Date(), deactivatedBy: 'timeout' },
    });
    return result.count;
  }

  async findById(id: string): Promise<PanicSession | null> {
    return this.prisma.panicSession.findUnique({ where: { id } });
  }

  async deactivate(id: string, method: 'pin' | 'timeout'): Promise<PanicSession> {
    return this.prisma.panicSession.update({
      where: { id },
      data: {
        status: PanicStatus.DEACTIVATED,
        endedAt: new Date(),
        deactivatedBy: method,
      },
    });
  }

  async appendRecordingUrl(id: string, url: string): Promise<void> {
    await this.prisma.panicSession.update({
      where: { id },
      data: { recordingUrls: { push: url } },
    });
  }

  async addLocationPoint(sessionId: string, lat: number, lng: number): Promise<void> {
    await this.prisma.panicLocationPoint.create({
      data: { sessionId, lat, lng },
    });
  }
}
