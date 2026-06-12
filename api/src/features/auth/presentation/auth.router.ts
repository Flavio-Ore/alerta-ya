import { Router } from 'express';

import { authMiddleware } from '../../../core/middleware/auth.middleware';
import { validate } from '../../../core/middleware/validate.middleware';
import { registerDeviceToken, removeDeviceToken, deleteAccount } from './auth.controller';
import { registerTokenSchema, deleteTokenSchema } from './auth.schema';

export const authRouter = Router();

// Registrar/actualizar token FCM — se llama en cada login
authRouter.post(
  '/device-token',
  authMiddleware,
  validate(registerTokenSchema),
  registerDeviceToken,
);

// Eliminar token FCM — se llama en logout
authRouter.delete(
  '/device-token',
  authMiddleware,
  validate(deleteTokenSchema),
  removeDeviceToken,
);

// Eliminar cuenta — borra datos de Postgres y Redis; cliente elimina Firebase Auth
authRouter.delete('/account', authMiddleware, deleteAccount);
