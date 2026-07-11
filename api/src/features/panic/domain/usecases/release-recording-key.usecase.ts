import { EscrowKeyRepository } from '../repositories/escrow-key.repository';
import { RecordingBlockRepository } from '../repositories/recording-block.repository';
import { KeyAccessAuditRepository } from '../repositories/key-access-audit.repository';
import { AppError } from '../../../../core/errors/AppError';

export interface ReleaseRecordingKeyInput {
  panicSessionId: string;
  requestedById: string;
  ipAddress: string | null;
}

export interface ReleaseRecordingKeyDeps {
  escrowRepo: EscrowKeyRepository;
  blockRepo: RecordingBlockRepository;
  auditRepo: KeyAccessAuditRepository;
  unwrapKey: (wrappedKey: Buffer, keyVersion: string) => Promise<Buffer>;
  getSignedUrl: (storagePath: string) => Promise<string | null>;
}

export interface ReleasedBlock {
  index: number;
  url: string;
}

export interface ReleaseRecordingKeyResult {
  aesKey: string; // base64
  blocks: ReleasedBlock[];
}

export async function releaseRecordingKey(
  input: ReleaseRecordingKeyInput,
  deps: ReleaseRecordingKeyDeps,
): Promise<ReleaseRecordingKeyResult> {
  try {
    const escrow = await deps.escrowRepo.findBySessionId(input.panicSessionId);
    if (!escrow) {
      throw new AppError(404, 'No hay clave de escrow para esta sesión');
    }

    const aesKeyBuffer = await deps.unwrapKey(escrow.wrappedKey, escrow.kmsKeyVersion);
    const storedBlocks = await deps.blockRepo.findBySessionId(input.panicSessionId);

    const blocks: ReleasedBlock[] = [];
    for (const block of storedBlocks) {
      const url = await deps.getSignedUrl(block.storagePath);
      if (url) {
        blocks.push({ index: block.blockIndex, url });
      }
    }

    await deps.auditRepo.create({
      panicSessionId: input.panicSessionId,
      requestedById: input.requestedById,
      ipAddress: input.ipAddress,
      result: 'SUCCESS',
    });

    return { aesKey: aesKeyBuffer.toString('base64'), blocks };
  } catch (err) {
    await deps.auditRepo.create({
      panicSessionId: input.panicSessionId,
      requestedById: input.requestedById,
      ipAddress: input.ipAddress,
      result: 'ERROR',
    });
    throw err;
  }
}
