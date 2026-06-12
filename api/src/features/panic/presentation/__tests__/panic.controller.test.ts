import { describe, it, expect, vi } from 'vitest';
import request from 'supertest';
import express from 'express';

import { errorHandlerMiddleware } from '../../../../core/middleware/errorHandler.middleware';
import { AppError } from '../../../../core/errors/AppError';

vi.mock('../../../../core/config/prisma', () => ({
  prisma: {},
  disconnectPrisma: vi.fn(),
}));

vi.mock('firebase-admin/auth', () => ({
  getAuth: vi.fn(() => ({
    verifyIdToken: vi.fn().mockResolvedValue({ uid: 'test-uid' }),
  })),
}));

vi.mock('../../infrastructure/prisma-panic.repository', () => ({
  PrismaPanicRepository: vi.fn().mockImplementation(() => ({})),
}));

vi.mock('../../../incidents/infrastructure/user-lookup.service', () => ({
  UserLookupService: vi.fn().mockImplementation(() => ({
    findOrCreate: vi.fn().mockResolvedValue({ id: 'user-id' }),
  })),
}));

vi.mock('../../infrastructure/gcs.client', () => ({
  generateSignedUrls: vi.fn().mockResolvedValue(['https://gcs.example.com/chunk-0.webm']),
}));

const mockSession = {
  id: 'session-uuid',
  startedAt: new Date().toISOString(),
  endedAt: null,
  lat: -12.1167,
  lng: -77.0372,
  status: 'ACTIVE',
  uploadParams: [
    { uploadUrl: 'https://api.cloudinary.com/v1_1/test/raw/upload', publicId: 'panic/session-uuid/0', timestamp: 1234567890, apiKey: 'test-key', signature: 'test-sig' },
  ],
};

vi.mock('../../domain/usecases/start-panic.usecase', () => ({
  startPanic: vi.fn().mockResolvedValue(mockSession),
}));

vi.mock('../../domain/usecases/stop-panic.usecase', () => ({
  stopPanic: vi.fn().mockResolvedValue({ ...mockSession, status: 'DEACTIVATED', endedAt: new Date().toISOString() }),
}));

const { panicRouter } = await import('../panic.router');

const app = express();
app.use(express.json());
app.use('/panic', panicRouter);
app.use(errorHandlerMiddleware);

describe('POST /panic/sessions', () => {
  it('GIVEN sin token WHEN POST THEN 401', async () => {
    const res = await request(app)
      .post('/panic/sessions')
      .send({ lat: -12.1167, lng: -77.0372 });

    expect(res.status).toBe(401);
  });

  it('GIVEN body sin lat/lng WHEN POST con token THEN 400', async () => {
    const res = await request(app)
      .post('/panic/sessions')
      .set('Authorization', 'Bearer valid-token')
      .send({});

    expect(res.status).toBe(400);
  });

  it('GIVEN payload válido WHEN POST con token THEN 201 con uploadParams', async () => {
    const res = await request(app)
      .post('/panic/sessions')
      .set('Authorization', 'Bearer valid-token')
      .send({ lat: -12.1167, lng: -77.0372 });

    expect(res.status).toBe(201);
    expect(res.body).toHaveProperty('uploadParams');
    expect(Array.isArray(res.body.uploadParams)).toBe(true);
  });

  it('GIVEN sesión ya activa WHEN POST THEN 409', async () => {
    const { startPanic } = await import('../../domain/usecases/start-panic.usecase');
    vi.mocked(startPanic).mockRejectedValueOnce(new AppError(409, 'Ya tenés una sesión activa'));

    const res = await request(app)
      .post('/panic/sessions')
      .set('Authorization', 'Bearer valid-token')
      .send({ lat: -12.1167, lng: -77.0372 });

    expect(res.status).toBe(409);
  });

  it('GIVEN sesión creada THEN respuesta no contiene userId ni firebaseUid', async () => {
    const res = await request(app)
      .post('/panic/sessions')
      .set('Authorization', 'Bearer valid-token')
      .send({ lat: -12.1167, lng: -77.0372 });

    const body = JSON.stringify(res.body);
    expect(body).not.toContain('userId');
    expect(body).not.toContain('firebaseUid');
  });
});

describe('DELETE /panic/sessions/:id', () => {
  it('GIVEN sin token WHEN DELETE THEN 401', async () => {
    const res = await request(app).delete('/panic/sessions/some-uuid');
    expect(res.status).toBe(401);
  });

  it('GIVEN id inválido (no UUID) WHEN DELETE THEN 400', async () => {
    const res = await request(app)
      .delete('/panic/sessions/not-a-uuid')
      .set('Authorization', 'Bearer valid-token');

    expect(res.status).toBe(400);
  });

  it('GIVEN sesión no encontrada WHEN DELETE THEN 404', async () => {
    const { stopPanic } = await import('../../domain/usecases/stop-panic.usecase');
    vi.mocked(stopPanic).mockRejectedValueOnce(new AppError(404, 'Sesión no encontrada'));

    const res = await request(app)
      .delete('/panic/sessions/00000000-0000-0000-0000-000000000000')
      .set('Authorization', 'Bearer valid-token');

    expect(res.status).toBe(404);
  });

  it('GIVEN usuario no es dueño WHEN DELETE THEN 403', async () => {
    const { stopPanic } = await import('../../domain/usecases/stop-panic.usecase');
    vi.mocked(stopPanic).mockRejectedValueOnce(new AppError(403, 'No tenés permiso'));

    const res = await request(app)
      .delete('/panic/sessions/00000000-0000-0000-0000-000000000000')
      .set('Authorization', 'Bearer valid-token');

    expect(res.status).toBe(403);
  });

  it('GIVEN sesión válida WHEN DELETE THEN 200 con status DEACTIVATED', async () => {
    const res = await request(app)
      .delete('/panic/sessions/00000000-0000-0000-0000-000000000000')
      .set('Authorization', 'Bearer valid-token');

    expect(res.status).toBe(200);
    expect(res.body.status).toBe('DEACTIVATED');
  });
});
