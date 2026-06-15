import { Router } from 'express';

import { authMiddleware } from '../../../core/middleware/auth.middleware';
import { validate } from '../../../core/middleware/validate.middleware';
import { startPanicSchema, stopPanicParamsSchema, updateLocationSchema } from './panic.schema';
import {
  startPanicSession,
  stopPanicSession,
  getActivePanicSessions,
  updatePanicLocationHandler,
} from './panic.controller';

const router = Router();

// Autoridades autenticadas ven sesiones activas — solo coordenadas, sin PII
router.get('/sessions/active', authMiddleware, getActivePanicSessions);
router.post('/sessions', authMiddleware, validate(startPanicSchema), startPanicSession);
router.delete('/sessions/:id', authMiddleware, validate(stopPanicParamsSchema, 'params'), stopPanicSession);
router.patch(
  '/sessions/:id/location',
  authMiddleware,
  validate(stopPanicParamsSchema, 'params'),
  validate(updateLocationSchema),
  updatePanicLocationHandler,
);

export { router as panicRouter };
