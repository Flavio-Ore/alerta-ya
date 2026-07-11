import { Router } from 'express';

import { authMiddleware } from '../../../core/middleware/auth.middleware';
import { validate } from '../../../core/middleware/validate.middleware';
import {
  startPanicSchema,
  stopPanicParamsSchema,
  updateLocationSchema,
  escrowKeySchema,
  registerBlockSchema,
  listSessionsQuerySchema,
} from './panic.schema';
import {
  startPanicSession,
  stopPanicSession,
  getActivePanicSessions,
  updatePanicLocationHandler,
  getEscrowPublicKeyHandler,
  submitEscrowKeyHandler,
  registerBlockHandler,
  releaseRecordingKeyHandler,
  getPanicSessionsHandler,
} from './panic.controller';

const router = Router();

// Autoridades autenticadas ven sesiones activas — solo coordenadas, sin PII
router.get('/sessions/active', authMiddleware, getActivePanicSessions);
router.get(
  '/sessions',
  authMiddleware,
  validate(listSessionsQuerySchema, 'query'),
  getPanicSessionsHandler,
);
router.post('/sessions', authMiddleware, validate(startPanicSchema), startPanicSession);
router.delete('/sessions/:id', authMiddleware, validate(stopPanicParamsSchema, 'params'), stopPanicSession);
router.patch(
  '/sessions/:id/location',
  authMiddleware,
  validate(stopPanicParamsSchema, 'params'),
  validate(updateLocationSchema),
  updatePanicLocationHandler,
);

router.get('/escrow/public-key', authMiddleware, getEscrowPublicKeyHandler);
router.post(
  '/sessions/:id/escrow-key',
  authMiddleware,
  validate(stopPanicParamsSchema, 'params'),
  validate(escrowKeySchema),
  submitEscrowKeyHandler,
);
router.post(
  '/sessions/:id/blocks',
  authMiddleware,
  validate(stopPanicParamsSchema, 'params'),
  validate(registerBlockSchema),
  registerBlockHandler,
);
// El check de rol de autoridad se hace dentro de releaseRecordingKeyHandler
// (no con authorityMiddleware) porque un intento denegado debe quedar
// registrado en KeyAccessAudit antes de responder 403.
router.post(
  '/sessions/:id/recordings/access',
  authMiddleware,
  validate(stopPanicParamsSchema, 'params'),
  releaseRecordingKeyHandler,
);

export { router as panicRouter };
