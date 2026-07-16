import { describe, it, expect, vi } from 'vitest';
import request from 'supertest';
import express from 'express';

// El controller importa el singleton de prisma, que hace $connect() al cargar el
// módulo y process.exit(1) si falla. Sin este mock, importar el router mataría el
// proceso de test. Tabla vacía → el artefacto vivo degrada al seed, que es
// exactamente lo que estos tests ejercitan.
vi.mock('../../../../core/config/prisma', () => ({
  prisma: {
    incident: {
      aggregate: async () => ({ _count: { _all: 0 }, _max: { createdAt: null } }),
      findMany: async () => [],
    },
  },
}));

// El endpoint /risk/predict llama al ML service. Mockeamos el cliente para no
// depender de la red; probamos el contrato del controller, no del ML.
const predictRiskMock = vi.fn();
vi.mock('../../infrastructure/predict.client', () => ({
  predictRisk: (...args: unknown[]) => predictRiskMock(...args),
}));

import { riskRouter } from '../risk.router';
import { errorHandlerMiddleware } from '../../../../core/middleware/errorHandler.middleware';

const app = express();
app.use(express.json());
app.use('/risk', riskRouter);
app.use(errorHandlerMiddleware);

describe('GET /risk', () => {
  it('GIVEN missing lat/lng THEN 400 (query validation)', async () => {
    const res = await request(app).get('/risk');
    expect(res.status).toBe(400);
  });

  it('GIVEN coordinates outside Lima THEN 422', async () => {
    const res = await request(app).get('/risk').query({ lat: 40.7, lng: -74.0 });
    expect(res.status).toBe(422);
  });

  it('GIVEN a valid Lima coordinate THEN 200 with an anonymous risk DTO', async () => {
    const res = await request(app).get('/risk').query({ lat: -12.0, lng: -77.05, hour: 21 });
    expect(res.status).toBe(200);
    expect(res.body).toHaveProperty('district');
    expect(res.body).toHaveProperty('level');
    expect(res.body).toHaveProperty('badHours');
    expect(res.body.hour).toBe(21);
    // never leaks identity
    expect(JSON.stringify(res.body)).not.toMatch(/userId|firebaseUid|email/i);
  });

  it('GIVEN an out-of-range hour THEN 400', async () => {
    const res = await request(app).get('/risk').query({ lat: -12.0, lng: -77.05, hour: 99 });
    expect(res.status).toBe(400);
  });
});

describe('GET /risk/predict', () => {
  it('GIVEN the ML model responds THEN 200 with available:true and the prediction', async () => {
    predictRiskMock.mockResolvedValueOnce({
      riskScore: 100,
      expectedCount: 2.651,
      confidence: 1.0,
      hour: 23,
      dayOfWeek: 5,
    });
    const res = await request(app)
      .get('/risk/predict')
      .query({ lat: -12.066, lng: -77.03, hour: 23, dayOfWeek: 5 });
    expect(res.status).toBe(200);
    expect(res.body.available).toBe(true);
    expect(res.body.riskScore).toBe(100);
    expect(res.body.dayOfWeek).toBe(5);
  });

  it('FAIL-OPEN: ML unavailable THEN 200 with available:false (never 500)', async () => {
    predictRiskMock.mockResolvedValueOnce(null);
    const res = await request(app)
      .get('/risk/predict')
      .query({ lat: -12.066, lng: -77.03, hour: 10, dayOfWeek: 2 });
    expect(res.status).toBe(200);
    expect(res.body.available).toBe(false);
    expect(res.body.dayOfWeek).toBe(2);
  });

  it('GIVEN coordinates outside Lima THEN 422', async () => {
    const res = await request(app).get('/risk/predict').query({ lat: 40.7, lng: -74.0 });
    expect(res.status).toBe(422);
  });

  it('GIVEN an out-of-range dayOfWeek THEN 400', async () => {
    const res = await request(app)
      .get('/risk/predict')
      .query({ lat: -12.0, lng: -77.05, dayOfWeek: 9 });
    expect(res.status).toBe(400);
  });
});
