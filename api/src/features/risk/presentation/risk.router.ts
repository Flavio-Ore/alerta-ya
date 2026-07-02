import { Router } from 'express';

import { validate } from '../../../core/middleware/validate.middleware';
import { riskQuerySchema } from './risk.schema';
import { getRiskForPoint } from './risk.controller';

const router = Router();

router.get('/', validate(riskQuerySchema, 'query'), getRiskForPoint);

export { router as riskRouter };
