import { PanicSessionRepository } from '../repositories/panic-session.repository';
import { RecordingBlockRepository } from '../repositories/recording-block.repository';
import { AppError } from '../../../../core/errors/AppError';

export interface RegisterRecordingBlockInput {
  panicSessionId: string;
  uid: string;
  blockIndex: number;
  storagePath: string;
}

export interface RegisterRecordingBlockDeps {
  panicRepo: PanicSessionRepository;
  blockRepo: RecordingBlockRepository;
  getUserId: (uid: string) => Promise<string>;
}

export async function registerRecordingBlock(
  input: RegisterRecordingBlockInput,
  deps: RegisterRecordingBlockDeps,
): Promise<void> {
  const session = await deps.panicRepo.findById(input.panicSessionId);
  if (!session) {
    throw new AppError(404, 'Sesión de pánico no encontrada');
  }

  const userId = await deps.getUserId(input.uid);
  if (session.userId !== userId) {
    throw new AppError(403, 'No autorizado para esta sesión');
  }

  await deps.blockRepo.upsert({
    panicSessionId: input.panicSessionId,
    blockIndex: input.blockIndex,
    storagePath: input.storagePath,
  });
}
