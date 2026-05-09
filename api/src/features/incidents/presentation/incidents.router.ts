import { Router } from 'express';

import { authMiddleware } from '../../../core/middleware/auth.middleware';
import { authorityMiddleware } from '../../../core/middleware/authority.middleware';
import { reportRateLimiterMiddleware } from '../../../core/middleware/rateLimiter.middleware';
import { validate } from '../../../core/middleware/validate.middleware';
import { createReportSchema, listIncidentsQuerySchema, idParamSchema, confirmSchema, updateStatusSchema, zoneConfirmSchema } from './incidents.schema';
import { listIncidents, getIncident, submitReport, patchIncidentStatus, confirmOrDenyIncident, respondZoneConfirm } from './incidents.controller';

const router = Router();

router.get('/', validate(listIncidentsQuerySchema, 'query'), listIncidents);
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
