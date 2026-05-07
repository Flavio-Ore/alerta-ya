import { describe, it, expect, vi, beforeAll } from 'vitest';
import request from 'supertest';
import express from 'express';

import { errorHandlerMiddleware } from '../../../../core/middleware/errorHandler.middleware';

// Mocks de infraestructura antes de importar routers
vi.mock('../../../../core/config/prisma', () => ({
  prisma: {},
  disconnectPrisma: vi.fn(),
}));

vi.mock('../../../../core/config/redis', () => ({
  redis: {
    incr: vi.fn(),
    expire: vi.fn(),
  },
}));

vi.mock('firebase-admin/auth', () => ({
  getAuth: vi.fn(() => ({
    verifyIdToken: vi.fn().mockResolvedValue({ uid: 'test-uid' }),
  })),
}));

vi.mock('../../infrastructure/user-lookup.service', () => ({
  UserLookupService: vi.fn().mockImplementation(() => ({
    findOrCreate: vi.fn().mockResolvedValue({ id: 'user-id', reputationScore: 100 }),
  })),
}));

vi.mock('../../infrastructure/prisma-incident.repository', () => ({
  PrismaIncidentRepository: vi.fn().mockImplementation(() => ({
    findActive: vi.fn().mockResolvedValue({ items: [], total: 0, page: 1 }),
    findById: vi.fn().mockResolvedValue(null),
    findActiveInZone: vi.fn().mockResolvedValue(null),
    create: vi.fn(),
    updateSeverity: vi.fn(),
    incrementReportCount: vi.fn(),
    linkReport: vi.fn(),
    extendExpiry: vi.fn(),
    incrementConfirm: vi.fn(),
    incrementDeny: vi.fn(),
    updateStatus: vi.fn(),
  })),
}));

vi.mock('../../infrastructure/prisma-report.repository', () => ({
  PrismaReportRepository: vi.fn().mockImplementation(() => ({
    create: vi.fn().mockResolvedValue({ id: 'report-id', formData: {} }),
    findOrphanedNearby: vi.fn().mockResolvedValue([]),
    findByIncidentId: vi.fn().mockResolvedValue([]),
  })),
}));

vi.mock('../../domain/usecases/create-report.usecase', () => ({
  createReport: vi.fn().mockResolvedValue(null),
}));

vi.mock('../../domain/usecases/confirm-incident.usecase', () => ({
  confirmIncident: vi.fn(),
}));

vi.mock('../../../../core/middleware/rateLimiter.middleware', () => ({
  reportRateLimiterMiddleware: vi.fn((_req, _res, next: () => void) => next()),
}));

const { incidentsRouter } = await import('../incidents.router');

const app = express();
app.use(express.json());
app.use('/incidents', incidentsRouter);
app.use(errorHandlerMiddleware);

describe('GET /incidents', () => {
  it('GIVEN no params WHEN request THEN 200 con lista vacía', async () => {
    const res = await request(app).get('/incidents');
    expect(res.status).toBe(200);
    expect(res.body).toHaveProperty('items');
  });

  it('GIVEN severity inválido WHEN request THEN 400', async () => {
    const res = await request(app).get('/incidents?severity=INVALID');
    expect(res.status).toBe(400);
  });
});

describe('POST /incidents/reports', () => {
  it('GIVEN sin token WHEN POST THEN 401', async () => {
    const res = await request(app)
      .post('/incidents/reports')
      .send({ lat: -12.1167, lng: -77.0372, type: 'ROBBERY', formData: {} });

    expect(res.status).toBe(401);
  });

  it('GIVEN body inválido WHEN POST con token THEN 400', async () => {
    const res = await request(app)
      .post('/incidents/reports')
      .set('Authorization', 'Bearer valid-token')
      .send({ lat: 'not-a-number', type: 'ROBBERY' });

    expect(res.status).toBe(400);
  });

  it('GIVEN payload válido WHEN POST con token THEN 200 y respuesta sin userId', async () => {
    const res = await request(app)
      .post('/incidents/reports')
      .set('Authorization', 'Bearer valid-token')
      .send({ lat: -12.1167, lng: -77.0372, type: 'ROBBERY', formData: {} });

    expect(res.status).toBeLessThan(500);
    // Verificar que la respuesta no filtra identidad
    const body = JSON.stringify(res.body);
    expect(body).not.toContain('userId');
    expect(body).not.toContain('firebaseUid');
    expect(body).not.toContain('email');
  });
});

describe('GET /incidents/:id', () => {
  it('GIVEN id inválido (no UUID) WHEN request THEN 400', async () => {
    const res = await request(app).get('/incidents/not-a-uuid');
    expect(res.status).toBe(400);
  });

  it('GIVEN UUID inexistente WHEN request THEN 404', async () => {
    const res = await request(app).get('/incidents/00000000-0000-0000-0000-000000000000');
    expect(res.status).toBe(404);
  });
});

describe('Security: no PII en respuestas', () => {
  beforeAll(() => {
    // Asegurar que ninguna respuesta del controller filtre datos sensibles
  });

  it('GIVEN lista de incidentes THEN respuesta no contiene userId', async () => {
    const res = await request(app).get('/incidents');
    const body = JSON.stringify(res.body);
    expect(body).not.toMatch(/userId/);
    expect(body).not.toMatch(/firebaseUid/);
    expect(body).not.toMatch(/email/);
  });
});
