import { Router } from 'express';

import { authMiddleware } from '../../../core/middleware/auth.middleware';
import { reportRateLimiterMiddleware } from '../../../core/middleware/rateLimiter.middleware';
import { validate } from '../../../core/middleware/validate.middleware';
import { createReportSchema, listIncidentsQuerySchema, idParamSchema, confirmSchema, zoneConfirmSchema } from './incidents.schema';
import { listIncidents, getIncident, submitReport, confirmOrDenyIncident, respondZoneConfirm } from './incidents.controller';

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

router.post(
  '/:id/confirm',
  authMiddleware,
  validate(idParamSchema, 'params'),
  validate(confirmSchema),
  confirmOrDenyIncident,
);

export { router as incidentsRouter };
