import { Router } from 'express';

import { validate } from '../../../core/middleware/validate.middleware';
import { zoneRiskParamsSchema } from './zones.schema';
import { zoneRisk } from './zones.controller';

const router = Router();

router.get('/:lat/:lng/risk', validate(zoneRiskParamsSchema, 'params'), zoneRisk);

export { router as zonesRouter };
