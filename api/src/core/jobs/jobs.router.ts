import { Router, Request, Response } from 'express';

import { prisma } from '../config/prisma';
import { expireIncidents } from './expire-incidents.job';
import { env } from '../config/env';

export const jobsRouter = Router();

// Protegido con un secret header — Cloud Scheduler lo manda en cada llamada
// En GCP: configurar el job con header X-Job-Secret: {env.JOB_SECRET}
jobsRouter.post('/expire-incidents', async (req: Request, res: Response) => {
  const secret = req.headers['x-job-secret'];
  if (secret !== env.JOB_SECRET) {
    res.status(401).json({ error: 'No autorizado' });
    return;
  }

  const { closed } = await expireIncidents(prisma);
  res.json({ ok: true, closed });
});
