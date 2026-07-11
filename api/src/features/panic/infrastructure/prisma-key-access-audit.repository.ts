import { PrismaClient } from '@prisma/client';

import { KeyAccessAuditRepository, KeyAccessAuditData } from '../domain/repositories/key-access-audit.repository';

export class PrismaKeyAccessAuditRepository implements KeyAccessAuditRepository {
  constructor(private readonly prisma: PrismaClient) {}

  async create(data: KeyAccessAuditData): Promise<void> {
    await this.prisma.keyAccessAudit.create({
      data: {
        panicSessionId: data.panicSessionId,
        requestedById: data.requestedById,
        ipAddress: data.ipAddress,
        result: data.result,
      },
    });
  }
}
