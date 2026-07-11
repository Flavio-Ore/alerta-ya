import { describe, it, expect, vi, beforeEach } from 'vitest';

import { storeEscrowKey } from '../domain/usecases/store-escrow-key.usecase';
import { AppError } from '../../../core/errors/AppError';

const mockPanicRepo = {
  findById: vi.fn(),
  create: vi.fn(),
  findActiveByUser: vi.fn(),
  findAllActive: vi.fn(),
  deactivate: vi.fn(),
  appendRecordingUrl: vi.fn(),
  addLocationPoint: vi.fn(),
};

const mockEscrowRepo = {
  create: vi.fn(),
  findBySessionId: vi.fn(),
};

const deps = {
  panicRepo: mockPanicRepo as any,
  escrowRepo: mockEscrowRepo as any,
  getUserId: vi.fn(),
};

const baseInput = {
  panicSessionId: 'ses-1',
  uid: 'firebase-uid-1',
  wrappedKey: Buffer.from('wrapped-bytes').toString('base64'),
  kmsKeyVersion: '1',
  algorithm: 'RSA_OAEP_256',
};

describe('storeEscrowKey', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('GIVEN sesión propia y sin clave previa WHEN se llama THEN crea el registro', async () => {
    mockPanicRepo.findById.mockResolvedValue({ id: 'ses-1', userId: 'user-1' });
    deps.getUserId.mockResolvedValue('user-1');
    mockEscrowRepo.findBySessionId.mockResolvedValue(null);

    await storeEscrowKey(baseInput, deps);

    expect(mockEscrowRepo.create).toHaveBeenCalledWith({
      panicSessionId: 'ses-1',
      wrappedKey: Buffer.from('wrapped-bytes'),
      kmsKeyVersion: '1',
      algorithm: 'RSA_OAEP_256',
    });
  });

  it('GIVEN sesión inexistente WHEN se llama THEN lanza 404', async () => {
    mockPanicRepo.findById.mockResolvedValue(null);
    deps.getUserId.mockResolvedValue('user-1');

    await expect(storeEscrowKey(baseInput, deps)).rejects.toThrow(AppError);
    expect(mockEscrowRepo.create).not.toHaveBeenCalled();
  });

  it('GIVEN sesión de otro usuario WHEN se llama THEN lanza 403', async () => {
    mockPanicRepo.findById.mockResolvedValue({ id: 'ses-1', userId: 'otro-user' });
    deps.getUserId.mockResolvedValue('user-1');

    await expect(storeEscrowKey(baseInput, deps)).rejects.toThrow(AppError);
    expect(mockEscrowRepo.create).not.toHaveBeenCalled();
  });

  it('GIVEN ya existe una clave para la sesión WHEN se llama THEN lanza 409', async () => {
    mockPanicRepo.findById.mockResolvedValue({ id: 'ses-1', userId: 'user-1' });
    deps.getUserId.mockResolvedValue('user-1');
    mockEscrowRepo.findBySessionId.mockResolvedValue({ wrappedKey: Buffer.from('x'), kmsKeyVersion: '1' });

    await expect(storeEscrowKey(baseInput, deps)).rejects.toThrow(AppError);
    expect(mockEscrowRepo.create).not.toHaveBeenCalled();
  });
});
