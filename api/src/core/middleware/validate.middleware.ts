import { Request, Response, NextFunction } from "express";
import { ZodTypeAny } from "zod";

import { AppError } from "../errors/AppError";

export function validate(
  schema: ZodTypeAny,
  target: "body" | "query" | "params" = "body",
) {
  return (req: Request, _res: Response, next: NextFunction): void => {
    const result = schema.safeParse(req[target]);
    if (!result.success) {
      const received = JSON.stringify(req[target]);
      const message = result.error.issues.map((i) => i.message).join(", ");
      console.error(`[validate] ${target} validation failed: ${message}`, { received });
      next(new AppError(400, message));
      return;
    }
    (req as unknown as Record<string, unknown>)[target] = result.data;
    next();
  };
}
