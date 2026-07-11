import { PrismaClient } from '@prisma/client';

import {
  EscrowKeyRepository,
  StoreEscrowKeyData,
  StoredEscrowKey,
} from '../domain/repositories/escrow-key.repository';
import { env } from '../../../core/config/env';

export class PrismaEscrowKeyRepository implements EscrowKeyRepository {
  constructor(private readonly prisma: PrismaClient) {}

  async create(data: StoreEscrowKeyData): Promise<void> {
    await this.prisma.panicSessionKey.create({
      data: {
        panicSessionId: data.panicSessionId,
        wrappedKey: data.wrappedKey,
        kmsKeyName: `projects/${env.KMS_PROJECT_ID}/locations/${env.KMS_LOCATION_ID}/keyRings/${env.KMS_KEY_RING_ID}/cryptoKeys/${env.KMS_KEY_ID}`,
        kmsKeyVersion: data.kmsKeyVersion,
        algorithm: data.algorithm,
      },
    });
  }

  async findBySessionId(panicSessionId: string): Promise<StoredEscrowKey | null> {
    const row = await this.prisma.panicSessionKey.findUnique({ where: { panicSessionId } });
    if (!row) return null;
    return { wrappedKey: Buffer.from(row.wrappedKey), kmsKeyVersion: row.kmsKeyVersion };
  }
}
