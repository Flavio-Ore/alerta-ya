import { Router } from 'express';

import { validate } from '../../../core/middleware/validate.middleware';
import { riskQuerySchema, predictQuerySchema } from './risk.schema';
import { getRiskForPoint, getRiskPrediction } from './risk.controller';

const router = Router();

router.get('/', validate(riskQuerySchema, 'query'), getRiskForPoint);
router.get('/predict', validate(predictQuerySchema, 'query'), getRiskPrediction);

export { router as riskRouter };
