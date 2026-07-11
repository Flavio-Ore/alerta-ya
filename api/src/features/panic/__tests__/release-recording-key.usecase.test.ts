import { describe, it, expect, vi, beforeEach } from 'vitest';

import { releaseRecordingKey } from '../domain/usecases/release-recording-key.usecase';
import { AppError } from '../../../core/errors/AppError';

const mockEscrowRepo = { create: vi.fn(), findBySessionId: vi.fn() };
const mockBlockRepo = { upsert: vi.fn(), findBySessionId: vi.fn() };
const mockAuditRepo = { create: vi.fn() };
const unwrapKey = vi.fn();
const getSignedUrl = vi.fn();

const deps = {
  escrowRepo: mockEscrowRepo as any,
  blockRepo: mockBlockRepo as any,
  auditRepo: mockAuditRepo as any,
  unwrapKey,
  getSignedUrl,
};

const baseInput = {
  panicSessionId: 'ses-1',
  requestedById: 'authority-1',
  ipAddress: '10.0.0.1',
};

describe('releaseRecordingKey', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('GIVEN escrow y bloques existentes WHEN se llama THEN devuelve la clave y las URLs, y audita SUCCESS', async () => {
    mockEscrowRepo.findBySessionId.mockResolvedValue({
      wrappedKey: Buffer.from('wrapped'),
      kmsKeyName: 'projects/p/locations/global/keyRings/r/cryptoKeys/k',
      kmsKeyVersion: '1',
    });
    mockBlockRepo.findBySessionId.mockResolvedValue([
      { blockIndex: 0, storagePath: 'gs://bucket/block_0.bin' },
      { blockIndex: 1, storagePath: 'gs://bucket/block_1.bin' },
    ]);
    unwrapKey.mockResolvedValue(Buffer.from('clave-aes'));
    getSignedUrl.mockImplementation(async (path: string) => `https://signed/${path}`);

    const result = await releaseRecordingKey(baseInput, deps);

    expect(unwrapKey).toHaveBeenCalledWith(
      Buffer.from('wrapped'),
      'projects/p/locations/global/keyRings/r/cryptoKeys/k',
      '1',
    );
    expect(result.aesKey).toBe(Buffer.from('clave-aes').toString('base64'));
    expect(result.blocks).toEqual([
      { index: 0, url: 'https://signed/gs://bucket/block_0.bin' },
      { index: 1, url: 'https://signed/gs://bucket/block_1.bin' },
    ]);
    expect(mockAuditRepo.create).toHaveBeenCalledWith({
      panicSessionId: 'ses-1',
      requestedById: 'authority-1',
      ipAddress: '10.0.0.1',
      result: 'SUCCESS',
    });
  });

  it('GIVEN sin clave de escrow WHEN se llama THEN lanza 404 y audita ERROR', async () => {
    mockEscrowRepo.findBySessionId.mockResolvedValue(null);

    await expect(releaseRecordingKey(baseInput, deps)).rejects.toThrow(AppError);
    expect(mockAuditRepo.create).toHaveBeenCalledWith({
      panicSessionId: 'ses-1',
      requestedById: 'authority-1',
      ipAddress: '10.0.0.1',
      result: 'ERROR',
    });
  });

  it('GIVEN bloques sin URL firmable WHEN se llama THEN los omite del resultado', async () => {
    mockEscrowRepo.findBySessionId.mockResolvedValue({
      wrappedKey: Buffer.from('wrapped'),
      kmsKeyName: 'projects/p/locations/global/keyRings/r/cryptoKeys/k',
      kmsKeyVersion: '1',
    });
    mockBlockRepo.findBySessionId.mockResolvedValue([
      { blockIndex: 0, storagePath: 'gs://bucket/block_0.bin' },
    ]);
    unwrapKey.mockResolvedValue(Buffer.from('clave-aes'));
    getSignedUrl.mockResolvedValue(null);

    const result = await releaseRecordingKey(baseInput, deps);

    expect(result.blocks).toEqual([]);
  });

  it('GIVEN falla auditRepo.create en el catch block THEN aún propaga el error original, no el error del audit', async () => {
    mockEscrowRepo.findBySessionId.mockResolvedValue(null);
    const originalError = new AppError(404, 'No hay clave de escrow para esta sesión');
    const auditError = new Error('DB unreachable during audit');
    mockAuditRepo.create.mockRejectedValue(auditError);

    await expect(releaseRecordingKey(baseInput, deps)).rejects.toThrow(originalError);
  });
});
