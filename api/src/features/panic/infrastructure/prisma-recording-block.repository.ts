import { PrismaClient } from '@prisma/client';

import {
  RecordingBlockRepository,
  RecordingBlockData,
  StoredRecordingBlock,
} from '../domain/repositories/recording-block.repository';

export class PrismaRecordingBlockRepository implements RecordingBlockRepository {
  constructor(private readonly prisma: PrismaClient) {}

  async upsert(data: RecordingBlockData): Promise<void> {
    await this.prisma.recordingBlock.upsert({
      where: {
        panicSessionId_blockIndex: {
          panicSessionId: data.panicSessionId,
          blockIndex: data.blockIndex,
        },
      },
      create: {
        panicSessionId: data.panicSessionId,
        blockIndex: data.blockIndex,
        storagePath: data.storagePath,
      },
      update: {
        storagePath: data.storagePath,
      },
    });
  }

  async findBySessionId(panicSessionId: string): Promise<StoredRecordingBlock[]> {
    const rows = await this.prisma.recordingBlock.findMany({
      where: { panicSessionId },
      orderBy: { blockIndex: 'asc' },
    });
    return rows.map((r) => ({ blockIndex: r.blockIndex, storagePath: r.storagePath }));
  }
}
