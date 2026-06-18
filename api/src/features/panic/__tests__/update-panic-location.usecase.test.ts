import { describe, it, expect, vi, beforeEach } from 'vitest';
import { updatePanicLocation } from '../domain/usecases/update-panic-location.usecase';
import { AppError } from '../../../core/errors/AppError';

const mockRepo = {
  findById: vi.fn(),
  addLocationPoint: vi.fn(),
  findActiveByUser: vi.fn(),
  create: vi.fn(),
  findAllActive: vi.fn(),
  update: vi.fn(),
};

const deps = {
  panicRepo: mockRepo as any,
  getUserId: vi.fn(),
};

describe('updatePanicLocation', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('agrega un punto de ubicación si la sesión existe y está activa', async () => {
    mockRepo.findById.mockResolvedValue({ id: 'ses-1', status: 'ACTIVE', userId: 'user-1' });
    (deps.getUserId as any).mockResolvedValue('user-1');
    mockRepo.addLocationPoint.mockResolvedValue(undefined);

    await updatePanicLocation(
      { sessionId: 'ses-1', uid: 'firebase-uid-1', lat: -12.04, lng: -77.03 },
      deps,
    );

    expect(mockRepo.addLocationPoint).toHaveBeenCalledWith('ses-1', -12.04, -77.03);
  });

  it('lanza 404 si la sesión no existe', async () => {
    mockRepo.findById.mockResolvedValue(null);
    (deps.getUserId as any).mockResolvedValue('user-1');

    await expect(
      updatePanicLocation({ sessionId: 'nope', uid: 'uid', lat: 0, lng: 0 }, deps),
    ).rejects.toThrow(AppError);
  });

  it('lanza 403 si la sesión no pertenece al usuario', async () => {
    mockRepo.findById.mockResolvedValue({ id: 'ses-2', status: 'ACTIVE', userId: 'otro-user' });
    (deps.getUserId as any).mockResolvedValue('user-atacante');

    await expect(
      updatePanicLocation({ sessionId: 'ses-2', uid: 'uid-atacante', lat: 0, lng: 0 }, deps),
    ).rejects.toThrow(AppError);
  });

  it('retorna sin error si la sesión ya no está activa', async () => {
    mockRepo.findById.mockResolvedValue({ id: 'ses-3', status: 'DEACTIVATED', userId: 'user-1' });
    (deps.getUserId as any).mockResolvedValue('user-1');

    await expect(
      updatePanicLocation({ sessionId: 'ses-3', uid: 'uid', lat: 0, lng: 0 }, deps),
    ).resolves.toBeUndefined();

    expect(mockRepo.addLocationPoint).not.toHaveBeenCalled();
  });
});
