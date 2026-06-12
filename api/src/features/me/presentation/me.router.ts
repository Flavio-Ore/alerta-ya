import { Router } from 'express';

import { authMiddleware } from '../../../core/middleware/auth.middleware';
import { validate } from '../../../core/middleware/validate.middleware';
import { getProfile, getPreferences, updatePreferences } from './me.controller';
import { updatePreferencesSchema } from './me.schema';

export const meRouter = Router();

// Perfil del usuario autenticado — sin PII (nombre/foto quedan en Firebase)
meRouter.get('/profile', authMiddleware, getProfile);

// Preferencias operativas (alertRadius, muteNotifications)
meRouter.get('/preferences', authMiddleware, getPreferences);
meRouter.patch(
  '/preferences',
  authMiddleware,
  validate(updatePreferencesSchema),
  updatePreferences,
);
