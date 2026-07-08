import express from "express";
import { createServer } from "http";
import { Server } from "socket.io";
import helmet from "helmet";
import cors from "cors";
import compression from "compression";

import { env } from "./core/config/env";
import { initFirebase } from "./core/config/firebase";
import { redis } from "./core/config/redis";
import { errorHandlerMiddleware } from "./core/middleware/errorHandler.middleware";
import { loggerMiddleware } from "./core/middleware/logger.middleware";

import { openApiSpec } from "./core/docs/openapi";

import { jobsRouter } from "./core/jobs/jobs.router";
import { authRouter } from "./features/auth/presentation/auth.router";
import { incidentsRouter } from "./features/incidents/presentation/incidents.router";
import { zonesRouter } from "./features/zones/presentation/zones.router";
import { riskRouter } from "./features/risk/presentation/risk.router";
import { panicRouter } from "./features/panic/presentation/panic.router";
import { notificationsRouter } from "./features/notifications/presentation/notifications.router";
import { adminRouter } from "./features/admin/presentation/admin.router";
import { meRouter } from "./features/me/presentation/me.router";
import { aiRouter } from "./features/ai/presentation/ai.router";

import { registerIncidentSocket } from "./sockets/incident.socket";
import { registerSocketAuth } from "./sockets/auth.socket";
import { registerNotificationListener } from "./features/notifications/domain/usecases/notify-incident.usecase";

const app = express();
const httpServer = createServer(app);

export const io = new Server(httpServer, {
  cors: { origin: env.WEB_URL, credentials: true },
});

app.use(
  helmet({
    contentSecurityPolicy: env.NODE_ENV === "production",
    xFrameOptions: { action: "deny" },
    xContentTypeOptions: true,
    strictTransportSecurity: true,
  }),
);
app.use(cors({ origin: env.WEB_URL, credentials: true }));
app.use(compression());
app.use(express.json({ limit: "1mb" }));
app.use(loggerMiddleware);

initFirebase();

// Docs — solo en no-producción (o si se fuerza con ENABLE_DOCS=true)
if (env.NODE_ENV !== "production") {
  app.get("/openapi.json", (_req, res) => {
    res.json(openApiSpec);
  });

  app.get("/docs", (_req, res) => {
    res.setHeader("Content-Type", "text/html");
    res.send(`<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8" />
  <title>AlertaYa API — Docs</title>
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <link rel="stylesheet" href="https://unpkg.com/swagger-ui-dist@5/swagger-ui.css" />
</head>
<body>
  <div id="swagger-ui"></div>
  <script src="https://unpkg.com/swagger-ui-dist@5/swagger-ui-bundle.js"></script>
  <script>
    SwaggerUIBundle({
      url: '/openapi.json',
      dom_id: '#swagger-ui',
      presets: [SwaggerUIBundle.presets.apis, SwaggerUIBundle.SwaggerUIStandalonePreset],
      layout: 'BaseLayout',
      deepLinking: true,
      tryItOutEnabled: true,
    });
  </script>
</body>
</html>`);
  });
}

// Routers
app.get("/health", (_req, res) => {
  res.json({
    status: "ok",
    service: "alertaya-api",
    timestamp: new Date().toISOString(),
  });
});

app.use("/auth", authRouter);
app.use("/incidents", incidentsRouter);
app.use("/zones", zonesRouter);
app.use("/risk", riskRouter);
app.use("/panic", panicRouter);
app.use("/notifications", notificationsRouter);
app.use("/me", meRouter);
app.use("/ai", aiRouter);
app.use("/internal/jobs", jobsRouter);
app.use("/admin/users", adminRouter);

// Error handler — siempre al final
app.use(errorHandlerMiddleware);

// WebSocket
registerSocketAuth(io);
registerIncidentSocket(io);

// Notificaciones push — escucha eventos del bus
registerNotificationListener(redis);

httpServer.listen(env.PORT, () => {
  console.log(`AlertaYa API running on port ${env.PORT}`);
  if (process.env.DEMO_MODE === "true") {
    console.warn(
      "⚠️  DEMO_MODE=true → threshold engine bypass activo (1 reporte publica incidente). NO usar en producción.",
    );
  }
});

export default app;
