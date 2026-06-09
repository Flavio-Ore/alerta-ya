import { Request, Response, NextFunction } from 'express';
import { AppError } from '../errors/AppError';

export function adminMiddleware(
  req: Request,
  _res: Response,
  next: NextFunction,
): void {
  if (!req.user) {
    next(new AppError(401, 'No autenticado'));
    return;
  }

  if (req.user.role !== 'ADMIN') {
    next(new AppError(403, 'Acceso restringido a administradores'));
    return;
  }

  next();
}
