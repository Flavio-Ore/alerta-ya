import { PanicSessionRepository } from '../repositories/panic-session.repository';
import { EscrowKeyRepository } from '../repositories/escrow-key.repository';
import { AppError } from '../../../../core/errors/AppError';

export interface StoreEscrowKeyInput {
  panicSessionId: string;
  uid: string;
  wrappedKey: string; // base64
  kmsKeyVersion: string;
  algorithm: string;
}

export interface StoreEscrowKeyDeps {
  panicRepo: PanicSessionRepository;
  escrowRepo: EscrowKeyRepository;
  getUserId: (uid: string) => Promise<string>;
}

export async function storeEscrowKey(
  input: StoreEscrowKeyInput,
  deps: StoreEscrowKeyDeps,
): Promise<void> {
  const session = await deps.panicRepo.findById(input.panicSessionId);
  if (!session) {
    throw new AppError(404, 'Sesión de pánico no encontrada');
  }

  const userId = await deps.getUserId(input.uid);
  if (session.userId !== userId) {
    throw new AppError(403, 'No autorizado para esta sesión');
  }

  const existing = await deps.escrowRepo.findBySessionId(input.panicSessionId);
  if (existing) {
    throw new AppError(409, 'Ya existe una clave de escrow para esta sesión');
  }

  await deps.escrowRepo.create({
    panicSessionId: input.panicSessionId,
    wrappedKey: Buffer.from(input.wrappedKey, 'base64'),
    kmsKeyVersion: input.kmsKeyVersion,
    algorithm: input.algorithm,
  });
}
