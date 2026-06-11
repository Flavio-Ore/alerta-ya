import { Request, Response, NextFunction } from "express";
import { getAuth } from "firebase-admin/auth";

import { AppError } from "../errors/AppError";

export type AuthorityRole = 'AUTHORITY' | 'ADMIN';
const KNOWN_ROLES: readonly AuthorityRole[] = ['AUTHORITY', 'ADMIN'];

// Extiende Request para incluir el usuario autenticado
declare global {
  namespace Express {
    interface Request {
      user?: {
        uid:       string;
        role?:     AuthorityRole | null; // Firebase custom claim — null si es ciudadano
        // Compat legacy — algunos tokens viejos podrían usar `authority: true`
        authority?: boolean;
      };
    }
  }
}

/**
 * Middleware de autenticación — verifica token Firebase en cada request.
 * Lee custom claim `role` (AUTHORITY|ADMIN) o el legacy `authority: true`.
 * No exponer el uid en respuestas públicas.
 */
export const authMiddleware = async (
  req: Request,
  _res: Response,
  next: NextFunction,
): Promise<void> => {
  const authHeader = req.headers.authorization;

  if (!authHeader?.startsWith("Bearer ")) {
    return next(new AppError(401, "Token de autenticación requerido"));
  }

  const token = authHeader.slice(7);

  try {
    const decodedToken = await getAuth().verifyIdToken(token);

    const rawRole = decodedToken['role'];
    const role = typeof rawRole === 'string' && KNOWN_ROLES.includes(rawRole as AuthorityRole)
      ? (rawRole as AuthorityRole)
      : null;

    req.user = {
      uid:       decodedToken.uid,
      role,
      authority: decodedToken['authority'] === true || role !== null,
    };
    next();
  } catch {
    next(new AppError(401, "Token inválido o expirado"));
  }
};
