import { describe, it, expect } from 'vitest';
import request from 'supertest';
import express from 'express';

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
