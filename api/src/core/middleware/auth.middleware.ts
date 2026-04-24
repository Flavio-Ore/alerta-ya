import { Request, Response, NextFunction } from "express";
import { getAuth } from "firebase-admin/auth";

import { AppError } from "../errors/AppError";

// Extiende Request para incluir el usuario autenticado
declare global {
  namespace Express {
    interface Request {
      user?: {
        uid: string;
      };
    }
  }
}

/**
 * Middleware de autenticación — verifica token Firebase en cada request.
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
    req.user = { uid: decodedToken.uid };
    next();
  } catch {
    next(new AppError(401, "Token inválido o expirado"));
  }
};
