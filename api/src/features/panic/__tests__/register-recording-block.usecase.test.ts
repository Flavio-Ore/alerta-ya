import { describe, it, expect, vi, beforeEach } from 'vitest';

import { registerRecordingBlock } from '../domain/usecases/register-recording-block.usecase';
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

const mockBlockRepo = {
  upsert: vi.fn(),
  findBySessionId: vi.fn(),
};

const deps = {
  panicRepo: mockPanicRepo as any,
  blockRepo: mockBlockRepo as any,
  getUserId: vi.fn(),
};

const baseInput = {
  panicSessionId: 'ses-1',
  uid: 'firebase-uid-1',
  blockIndex: 2,
  storagePath: 'gs://alertaya-bucket/panic/ses-1/audio/block_2.bin',
};

describe('registerRecordingBlock', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('GIVEN sesión propia WHEN se llama THEN hace upsert del bloque', async () => {
    mockPanicRepo.findById.mockResolvedValue({ id: 'ses-1', userId: 'user-1' });
    deps.getUserId.mockResolvedValue('user-1');

    await registerRecordingBlock(baseInput, deps);

    expect(mockBlockRepo.upsert).toHaveBeenCalledWith({
      panicSessionId: 'ses-1',
      blockIndex: 2,
      storagePath: baseInput.storagePath,
    });
  });

  it('GIVEN sesión inexistente WHEN se llama THEN lanza 404', async () => {
    mockPanicRepo.findById.mockResolvedValue(null);
    deps.getUserId.mockResolvedValue('user-1');

    await expect(registerRecordingBlock(baseInput, deps)).rejects.toThrow(AppError);
    expect(mockBlockRepo.upsert).not.toHaveBeenCalled();
  });

  it('GIVEN sesión de otro usuario WHEN se llama THEN lanza 403', async () => {
    mockPanicRepo.findById.mockResolvedValue({ id: 'ses-1', userId: 'otro-user' });
    deps.getUserId.mockResolvedValue('user-1');

    await expect(registerRecordingBlock(baseInput, deps)).rejects.toThrow(AppError);
    expect(mockBlockRepo.upsert).not.toHaveBeenCalled();
  });
});
