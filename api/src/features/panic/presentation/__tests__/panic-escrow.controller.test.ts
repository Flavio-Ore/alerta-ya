import { describe, it, expect, vi } from 'vitest';
import request from 'supertest';
import express from 'express';

import { errorHandlerMiddleware } from '../../../../core/middleware/errorHandler.middleware';

vi.mock('../../../../core/config/prisma', () => ({ prisma: {}, disconnectPrisma: vi.fn() }));

vi.mock('firebase-admin/auth', () => ({
  getAuth: vi.fn(() => ({
    verifyIdToken: vi.fn().mockImplementation(async (token: string) => {
      if (token === 'authority-token') return { uid: 'authority-uid', role: 'AUTHORITY' };
      return { uid: 'citizen-uid' };
    }),
  })),
}));

vi.mock('../../infrastructure/prisma-panic.repository', () => ({
  PrismaPanicRepository: vi.fn().mockImplementation(() => ({
    findById: vi.fn().mockResolvedValue({ id: '11111111-1111-1111-1111-111111111111', userId: 'user-id' }),
  })),
}));
vi.mock('../../infrastructure/prisma-escrow-key.repository', () => ({
  PrismaEscrowKeyRepository: vi.fn().mockImplementation(() => ({})),
}));
vi.mock('../../infrastructure/prisma-recording-block.repository', () => ({
  PrismaRecordingBlockRepository: vi.fn().mockImplementation(() => ({})),
}));
const auditCreateMock = vi.fn().mockResolvedValue(undefined);
vi.mock('../../infrastructure/prisma-key-access-audit.repository', () => ({
  PrismaKeyAccessAuditRepository: vi.fn().mockImplementation(() => ({ create: auditCreateMock })),
}));
vi.mock('../../../incidents/infrastructure/user-lookup.service', () => ({
  UserLookupService: vi.fn().mockImplementation(() => ({
    findOrCreate: vi.fn().mockResolvedValue({ id: 'user-id' }),
  })),
}));
vi.mock('../../../../core/config/kms', () => ({
  getEscrowPublicKey: vi.fn().mockResolvedValue({ publicKeyPem: 'PEM', keyVersion: '1' }),
  unwrapEscrowKey: vi.fn(),
}));
vi.mock('../../../../core/config/firebase', () => ({
  getSignedUrl: vi.fn().mockResolvedValue('https://signed-url'),
}));
vi.mock('../../domain/usecases/store-escrow-key.usecase', () => ({
  storeEscrowKey: vi.fn().mockResolvedValue(undefined),
}));
vi.mock('../../domain/usecases/register-recording-block.usecase', () => ({
  registerRecordingBlock: vi.fn().mockResolvedValue(undefined),
}));
vi.mock('../../domain/usecases/release-recording-key.usecase', () => ({
  releaseRecordingKey: vi.fn().mockResolvedValue({ aesKey: 'base64key', blocks: [] }),
}));

const { panicRouter } = await import('../panic.router');

const app = express();
app.use(express.json());
app.use('/panic', panicRouter);
app.use(errorHandlerMiddleware);

describe('GET /panic/escrow/public-key', () => {
  it('devuelve la pública KMS con token válido', async () => {
    const res = await request(app)
      .get('/panic/escrow/public-key')
      .set('Authorization', 'Bearer citizen-token');

    expect(res.status).toBe(200);
    expect(res.body).toEqual({ publicKeyPem: 'PEM', kmsKeyVersion: '1' });
  });

  it('rechaza sin token', async () => {
    const res = await request(app).get('/panic/escrow/public-key');
    expect(res.status).toBe(401);
  });
});

describe('POST /panic/sessions/:id/escrow-key', () => {
  it('acepta un wrapped key válido', async () => {
    const res = await request(app)
      .post('/panic/sessions/11111111-1111-1111-1111-111111111111/escrow-key')
      .set('Authorization', 'Bearer citizen-token')
      .send({ wrappedKey: 'd2FubmVk', kmsKeyVersion: '1', algorithm: 'RSA_OAEP_256' });

    expect(res.status).toBe(201);
  });

  it('rechaza body inválido (algorithm incorrecto)', async () => {
    const res = await request(app)
      .post('/panic/sessions/11111111-1111-1111-1111-111111111111/escrow-key')
      .set('Authorization', 'Bearer citizen-token')
      .send({ wrappedKey: 'd2FubmVk', kmsKeyVersion: '1', algorithm: 'AES' });

    expect(res.status).toBe(400);
  });
});

describe('POST /panic/sessions/:id/blocks', () => {
  it('registra un bloque válido', async () => {
    const res = await request(app)
      .post('/panic/sessions/11111111-1111-1111-1111-111111111111/blocks')
      .set('Authorization', 'Bearer citizen-token')
      .send({ blockIndex: 0, storagePath: 'gs://bucket/block_0.bin' });

    expect(res.status).toBe(201);
  });

  it('rechaza storagePath sin prefijo gs://', async () => {
    const res = await request(app)
      .post('/panic/sessions/11111111-1111-1111-1111-111111111111/blocks')
      .set('Authorization', 'Bearer citizen-token')
      .send({ blockIndex: 0, storagePath: 'https://bucket/block_0.bin' });

    expect(res.status).toBe(400);
  });
});

describe('POST /panic/sessions/:id/recordings/access', () => {
  it('permite acceso a una autoridad', async () => {
    const res = await request(app)
      .post('/panic/sessions/11111111-1111-1111-1111-111111111111/recordings/access')
      .set('Authorization', 'Bearer authority-token');

    expect(res.status).toBe(200);
    expect(res.body).toEqual({ aesKey: 'base64key', blocks: [] });
  });

  it('rechaza a un ciudadano sin rol de autoridad', async () => {
    const res = await request(app)
      .post('/panic/sessions/11111111-1111-1111-1111-111111111111/recordings/access')
      .set('Authorization', 'Bearer citizen-token');

    expect(res.status).toBe(403);
  });

  it('audita DENIED cuando un ciudadano sin rol de autoridad intenta acceder', async () => {
    auditCreateMock.mockClear();

    const res = await request(app)
      .post('/panic/sessions/11111111-1111-1111-1111-111111111111/recordings/access')
      .set('Authorization', 'Bearer citizen-token');

    expect(res.status).toBe(403);
    expect(auditCreateMock).toHaveBeenCalledWith({
      panicSessionId: '11111111-1111-1111-1111-111111111111',
      requestedById: 'user-id',
      ipAddress: expect.anything(),
      result: 'DENIED',
    });
  });
});
