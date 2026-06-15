import { Router } from 'express';

import { authMiddleware } from '../../../core/middleware/auth.middleware';
import { authorityMiddleware } from '../../../core/middleware/authority.middleware';
import { validate } from '../../../core/middleware/validate.middleware';
import { analyzeSchema } from './ai.schema';
import { analyze } from './ai.controller';

const router = Router();

// POST /ai/analyze — chat de análisis para autoridades (grounded en data histórica)
router.post('/analyze', authMiddleware, authorityMiddleware, validate(analyzeSchema), analyze);

export { router as aiRouter };
