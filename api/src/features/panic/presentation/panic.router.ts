import { Router } from 'express';

import { authMiddleware } from '../../../core/middleware/auth.middleware';
import { validate } from '../../../core/middleware/validate.middleware';
import { startPanicSchema, stopPanicParamsSchema } from './panic.schema';
import { startPanicSession, stopPanicSession } from './panic.controller';

const router = Router();

router.post('/sessions', authMiddleware, validate(startPanicSchema), startPanicSession);
router.delete('/sessions/:id', authMiddleware, validate(stopPanicParamsSchema, 'params'), stopPanicSession);

export { router as panicRouter };
