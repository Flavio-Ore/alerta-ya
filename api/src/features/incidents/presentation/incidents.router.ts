import { Router } from 'express';

import { authMiddleware } from '../../../core/middleware/auth.middleware';
import { authorityMiddleware } from '../../../core/middleware/authority.middleware';
import { reportRateLimiterMiddleware } from '../../../core/middleware/rateLimiter.middleware';
import { validate } from '../../../core/middleware/validate.middleware';
import { createReportSchema, listIncidentsQuerySchema, listMyReportsQuerySchema, idParamSchema, confirmSchema, updateStatusSchema, zoneConfirmSchema, reportIdParamSchema } from './incidents.schema';
import { listIncidents, getIncident, submitReport, patchIncidentStatus, confirmOrDenyIncident, respondZoneConfirm, listMyReports, cancelReport } from './incidents.controller';

const router = Router();

router.get('/', validate(listIncidentsQuerySchema, 'query'), listIncidents);
// "Mis reportes" del ciudadano autenticado — debe ir ANTES de '/:id' para no chocar con la ruta uuid
router.get(
  '/reports/mine',
  authMiddleware,
  validate(listMyReportsQuerySchema, 'query'),
  listMyReports,
);
router.get('/:id', validate(idParamSchema, 'params'), getIncident);
router.post(
  '/reports',
  authMiddleware,
  reportRateLimiterMiddleware,
  validate(createReportSchema),
  submitReport,
);
router.post(
  '/zone-confirmations',
  authMiddleware,
  validate(zoneConfirmSchema),
  respondZoneConfirm,
);

// Cancelar reporte pendiente (solo owner, solo si no está vinculado a incidente)
router.delete(
  '/reports/:reportId',
  authMiddleware,
  validate(reportIdParamSchema, 'params'),
  cancelReport,
);

// Solo autoridades — actualizar estado + feedback al ciudadano
router.patch(
  '/:id/status',
  authMiddleware,
  authorityMiddleware,
  validate(idParamSchema, 'params'),
  validate(updateStatusSchema),
  patchIncidentStatus,
);

router.post(
  '/:id/confirm',
  authMiddleware,
  validate(idParamSchema, 'params'),
  validate(confirmSchema),
  confirmOrDenyIncident,
);

export { router as incidentsRouter };
