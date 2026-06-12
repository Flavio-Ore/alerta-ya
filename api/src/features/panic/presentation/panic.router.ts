import { Router } from 'express';

import { authMiddleware } from '../../../core/middleware/auth.middleware';
import { validate } from '../../../core/middleware/validate.middleware';
import { startPanicSchema, stopPanicParamsSchema } from './panic.schema';
import {
  startPanicSession,
  stopPanicSession,
  getActivePanicSessions,
} from './panic.controller';

const router = Router();

// Autoridades autenticadas ven sesiones activas — solo coordenadas, sin PII
router.get('/sessions/active', authMiddleware, getActivePanicSessions);
router.post('/sessions', authMiddleware, validate(startPanicSchema), startPanicSession);
router.delete('/sessions/:id', authMiddleware, validate(stopPanicParamsSchema, 'params'), stopPanicSession);

export { router as panicRouter };
