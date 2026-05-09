import { Request, Response, NextFunction } from 'express';
import { AppError } from '../errors/AppError';

/**
 * Middleware que verifica que el usuario autenticado es una autoridad.
 *
 * Requiere que authMiddleware haya corrido antes (req.user debe existir).
 *
 * Cómo funciona:
 * - Firebase Admin SDK permite agregar custom claims a un token: { authority: true }
 * - El panel web de autoridades usa cuentas Firebase con ese claim seteado
 * - Cualquier ciudadano autenticado sin ese claim recibe 403
 *
 * Para setear el claim en una cuenta (solo admin puede hacerlo):
 *   await admin.auth().setCustomUserClaims(uid, { authority: true })
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

  // El auth middleware ya verificó el token y decodificó los custom claims
  const claims = req.user as { uid: string; authority?: boolean };

  if (!claims.authority) {
    next(new AppError(403, 'Acceso restringido a autoridades'));
    return;
  }

  next();
}
