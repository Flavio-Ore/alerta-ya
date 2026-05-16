import { Server } from "socket.io";
import { getAuth } from "firebase-admin/auth";

import { env } from "../core/config/env";

export function registerSocketAuth(io: Server): void {
  io.use(async (socket, next) => {
    // Validar origen
    const origin = socket.handshake.headers.origin;
    if (origin && origin !== env.WEB_URL) {
      next(new Error("Origen no autorizado"));
      return;
    }

    // Validar token (si se proporciona)
    const token = socket.handshake.auth["token"] as string | undefined;
    if (!token) {
      // Clientes sin token pueden conectarse en modo lectura (ciudadanos en MVP)
      next();
      return;
    }

    try {
      await getAuth().verifyIdToken(token);
      next();
    } catch {
      next(new Error("Token inválido"));
    }
  });
}
