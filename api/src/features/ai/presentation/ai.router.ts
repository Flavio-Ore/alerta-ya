import { Router } from 'express';

import { authMiddleware } from '../../../core/middleware/auth.middleware';
import { authorityMiddleware } from '../../../core/middleware/authority.middleware';
import { validate } from '../../../core/middleware/validate.middleware';
import { analyzeSchema } from './ai.schema';
import { analyze, analyzeStream } from './ai.controller';

const router = Router();

// POST /ai/analyze — chat de análisis para autoridades (grounded en data histórica)
router.post('/analyze', authMiddleware, authorityMiddleware, validate(analyzeSchema), analyze);
router.post(
  '/analyze-stream',
  authMiddleware,
  authorityMiddleware,
  validate(analyzeSchema),
  analyzeStream,
);

export { router as aiRouter };
