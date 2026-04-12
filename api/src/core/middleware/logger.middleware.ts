import { Request, Response, NextFunction } from 'express';

/**
 * Logger de requests.
 * NUNCA loggear: tokens, userId de reportantes, coordenadas GPS del usuario,
 * contenido de formularios vinculados a userId.
 * Solo loggear: timestamp, método, ruta, status code.
 */
export const loggerMiddleware = (
  req: Request,
  res: Response,
  next: NextFunction,
): void => {
  const start = Date.now();

  res.on('finish', () => {
    const duration = Date.now() - start;
    // Log seguro — sin datos personales
    console.log(`${new Date().toISOString()} ${req.method} ${req.path} ${res.statusCode} ${duration}ms`);
  });

  next();
};
