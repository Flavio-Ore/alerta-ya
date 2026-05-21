import { Request, Response, NextFunction } from 'express';
import { AppError } from '../errors/AppError';

/**
 * Middleware que verifica que el usuario autenticado es una autoridad o admin.
 *
 * Requiere que authMiddleware haya corrido antes (req.user debe existir).
 *
 * Convención de custom claims (Firebase):
 *   - role: 'AUTHORITY' → autoridad operativa (PNP, Serenazgo, Municipalidad)
 *   - role: 'ADMIN'     → super-usuario del sistema
 *   - sin claim         → ciudadano común (rechazado por este middleware)
 *
 * Para setear el claim usar el script: api/scripts/set-role.ts
 *
 * Compat legacy: tokens con `authority: true` (sin role) también se aceptan.
 */
export function authorityMiddleware(
  req: Request,
  _res: Response,
  next: NextFunction,
): void {
  if (!req.user) {
    next(new AppError(401, 'No autenticado'));
    return;
  }

  const hasRole = req.user.role === 'AUTHORITY' || req.user.role === 'ADMIN';
  const hasLegacyAuthority = req.user.authority === true;

  if (!hasRole && !hasLegacyAuthority) {
    next(new AppError(403, 'Acceso restringido a autoridades'));
    return;
  }

  next();
}
