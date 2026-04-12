import express from 'express';
import { createServer } from 'http';
import { Server } from 'socket.io';
import helmet from 'helmet';
import cors from 'cors';
import compression from 'compression';

import { env } from './core/config/env';
import { initFirebase } from './core/config/firebase';
import { errorHandlerMiddleware } from './core/middleware/errorHandler.middleware';
import { loggerMiddleware } from './core/middleware/logger.middleware';

const app = express();
const httpServer = createServer(app);

// Socket.io — mapa en vivo
export const io = new Server(httpServer, {
  cors: { origin: env.WEB_URL, credentials: true },
});

// Middlewares de seguridad
app.use(helmet({
  contentSecurityPolicy: true,
  xFrameOptions: { action: 'deny' },
  xContentTypeOptions: true,
  strictTransportSecurity: true,
}));
app.use(cors({ origin: env.WEB_URL, credentials: true }));
app.use(compression());
app.use(express.json({ limit: '1mb' }));
app.use(loggerMiddleware);

// Firebase Admin init
initFirebase();

// Health check
app.get('/health', (_req, res) => {
  res.json({ status: 'ok', service: 'alertaya-api', timestamp: new Date().toISOString() });
});

// TODO(routes): montar routers de features
// app.use('/incidents', incidentsRouter);
// app.use('/panic', panicRouter);

// Error handler — siempre al final
app.use(errorHandlerMiddleware);

httpServer.listen(env.PORT, () => {
  console.log(`AlertaYa API running on port ${env.PORT}`);
});

export default app;
