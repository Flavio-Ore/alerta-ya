import { Router } from 'express';

import { authMiddleware } from '../../../core/middleware/auth.middleware';
import { validate } from '../../../core/middleware/validate.middleware';
import { listNotifications, markNotificationsRead } from './notifications.controller';
import { listNotificationsSchema, markReadSchema } from './notifications.schema';

export const notificationsRouter = Router();

// Historial de notificaciones del usuario — alimenta el tab "Alertas" en mobile
notificationsRouter.get(
  '/',
  authMiddleware,
  validate(listNotificationsSchema, 'query'),
  listNotifications,
);

// Marcar como leídas (por IDs o todas a la vez)
notificationsRouter.patch(
  '/read',
  authMiddleware,
  validate(markReadSchema),
  markNotificationsRead,
);
