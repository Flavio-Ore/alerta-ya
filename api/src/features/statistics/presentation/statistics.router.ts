import { Router } from 'express';

import { authMiddleware } from '../../../core/middleware/auth.middleware';
import { authorityMiddleware } from '../../../core/middleware/authority.middleware';
import { validate } from '../../../core/middleware/validate.middleware';
import { statsQuerySchema } from './statistics.schema';
import { handleGetStats } from './statistics.controller';

const router = Router();

router.get(
  '/',
  authMiddleware,
  authorityMiddleware,
  validate(statsQuerySchema, 'query'),
  handleGetStats,
);

export { router as statisticsRouter };
