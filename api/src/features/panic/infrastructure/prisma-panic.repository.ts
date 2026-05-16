import { PrismaClient, PanicSession, PanicStatus } from '@prisma/client';

import { PanicSessionRepository, CreatePanicSessionData } from '../domain/repositories/panic-session.repository';

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
}
