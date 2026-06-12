import { Router, Request, Response } from 'express';

import { prisma } from '../config/prisma';
import { expireIncidents } from './expire-incidents.job';
import { env } from '../config/env';
import { eventBus, IncidentEvents, PanicEvents } from '../events/event-bus';
import { toPublicDTO } from '../../features/incidents/domain/entities/incident.entity';
import { PrismaPanicRepository } from '../../features/panic/infrastructure/prisma-panic.repository';

export const jobsRouter = Router();

function authorizeJob(req: Request, res: Response): boolean {
  const secret = req.headers['x-job-secret'];
  if (secret !== env.JOB_SECRET) {
    res.status(401).json({ error: 'No autorizado' });
    return false;
  }
  return true;
}

// Protegido con un secret header — Cloud Scheduler lo manda en cada llamada
// En GCP: configurar el job con header X-Job-Secret: {env.JOB_SECRET}
jobsRouter.post('/expire-incidents', async (req: Request, res: Response) => {
  if (!authorizeJob(req, res)) return;

  const { closed } = await expireIncidents(prisma);
  res.json({ ok: true, closed });
});

/**
 * Expira sesiones de pánico huérfanas (app crasheada, batería muerta).
 * Marca como DEACTIVATED las sesiones ACTIVE con más de 60 minutos.
 * Emite panic:stopped por WebSocket para que el panel de autoridades las elimine.
 * Correr cada 15 minutos vía Cloud Scheduler en producción.
 */
jobsRouter.post('/expire-panic-sessions', async (req: Request, res: Response) => {
  if (!authorizeJob(req, res)) return;

  const panicRepo = new PrismaPanicRepository(prisma);
  // Sesiones con más de 60 min (max recording time) son consideradas huérfanas
  const expired = await panicRepo.expireOldSessions(60);

  // Notificar al panel de autoridades para que limpie los marcadores en tiempo real
  if (expired > 0) {
    // No tenemos los IDs individuales desde updateMany — el panel
    // recibirá la invalidación via polling de 30s o en el próximo WS event.
    // Para el MVP esto es suficiente.
    eventBus.emit(PanicEvents.STOPPED, { id: 'bulk-expiry' });
  }

  res.json({ ok: true, expired });
});

/**
 * DEV ONLY — emite el evento incident.new para un incidente existente.
 * Usado por scripts/emit-test-incident.ts para probar WebSocket sin tener
 * que pasar por el flujo completo de reportes ciudadanos + threshold engine.
 *
 * Disponible solo en NODE_ENV !== 'production'.
 */
jobsRouter.post('/emit-incident-event', async (req: Request, res: Response) => {
  if (env.NODE_ENV === 'production') {
    res.status(404).json({ error: 'Not found' });
    return;
  }
  if (!authorizeJob(req, res)) return;

  const { incidentId, event } = req.body as {
    incidentId: string;
    event:      'new' | 'updated';
  };

  if (!incidentId) {
    res.status(400).json({ error: 'incidentId requerido' });
    return;
  }

  const incident = await prisma.incident.findUnique({ where: { id: incidentId } });
  if (!incident) {
    res.status(404).json({ error: 'Incidente no existe' });
    return;
  }

  const dto = toPublicDTO(incident);
  const channel = event === 'updated' ? IncidentEvents.UPDATED : IncidentEvents.NEW;
  eventBus.emit(channel, dto);

  res.json({ ok: true, emitted: channel, incidentId: dto.id });
});
