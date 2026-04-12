import { Request, Response, NextFunction } from 'express';

import { AppError } from '../errors/AppError';

export const errorHandlerMiddleware = (
  err: Error,
  _req: Request,
  res: Response,
  _next: NextFunction,
): void => {
  if (err instanceof AppError) {
    res.status(err.statusCode).json({
      error: {
        message: err.message,
        code: err.statusCode,
      },
    });
    return;
  }

  // Error no operacional — no exponer detalles internos
  console.error('Unhandled error:', err.message);
  res.status(500).json({
    error: {
      message: 'Error interno del servidor',
      code: 500,
    },
  });
};
