import { Router } from 'express';

import { authMiddleware } from '../../../core/middleware/auth.middleware';
import { adminMiddleware } from '../../../core/middleware/admin.middleware';
import { validate } from '../../../core/middleware/validate.middleware';
import {
  createUserSchema,
  updateUserSchema,
  listUsersQuerySchema,
} from './admin.schema';
import {
  listUsers,
  getUser,
  createUser,
  updateUser,
  disableUser,
  enableUser,
} from './admin.controller';

const router = Router();

router.use(authMiddleware, adminMiddleware);

router.get('/', validate(listUsersQuerySchema, 'query'), listUsers);
router.get('/:uid', getUser);
router.post('/', validate(createUserSchema), createUser);
router.patch('/:uid', validate(updateUserSchema), updateUser);
router.delete('/:uid/disable', disableUser);
router.post('/:uid/enable', enableUser);

export { router as adminRouter };
