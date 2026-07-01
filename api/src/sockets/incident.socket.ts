import { Server, Socket } from 'socket.io';

import {
  eventBus,
  IncidentEvents,
  ConfirmRequestPayload,
  IncidentEventPayload,
  StatusChangedForReportersPayload,
  PanicEvents,
  PanicStartedPayload,
  PanicStoppedPayload,
} from '../core/events/event-bus';
import { getDistrict } from '../core/utils/geo.utils';
import { PublicIncidentDTO } from '../features/incidents/domain/entities/incident.entity';
import { prisma } from '../core/config/prisma';
import { redis } from '../core/config/redis';
import { PrismaDeviceTokenRepository } from '../features/auth/infrastructure/prisma-device-token.repository';
import { sendConfirmRequestPush } from '../features/notifications/infrastructure/fcm.service';
import Redis from 'ioredis';

const deviceTokenRepo = new PrismaDeviceTokenRepository(prisma);

const LIMA_ROOM = 'Lima';

// Room por distrito — para incidentes publicados
function districtRoom(district: string): string {
  return `district:${district}`;
}

// Room de proximidad — para confirm-request a testigos cercanos.
// TILE_SIZE = 0.003° ≈ 330m en Lima. Con grid 3×3 al emitir, max ~1km radio.
// Justificación del tamaño: solo gente que estuvo físicamente cerca del incidente
// puede confirmar haber visto algo — 300m cubre vecindario inmediato (3 cuadras).
const TILE_SIZE = 0.003;

function tileIndex(coord: number): number {
  return Math.floor(coord / TILE_SIZE);
}

function proximityRoom(lat: number, lng: number): string {
  return `prox:${tileIndex(lat)}:${tileIndex(lng)}`;
}

// Room privado por usuario — para eventos dirigidos a un reportante específico
function userRoom(firebaseUid: string): string {
  return `user:${firebaseUid}`;
}

async function joinRooms(socket: Socket, lat: number, lng: number): Promise<void> {
  // Salir de rooms anteriores de distrito y proximidad
  const previous = [...socket.rooms].filter(
    (r) => r.startsWith('district:') || r.startsWith('prox:'),
  );
  for (const room of previous) {
    await socket.leave(room);
  }

  const district = getDistrict(lat, lng);
  const dRoom = districtRoom(district);
  const pRoom = proximityRoom(lat, lng);
  await socket.join(dRoom);
  await socket.join(pRoom);
  console.log(`[WS] ${socket.id} joined ${dRoom} + ${pRoom} (lat=${lat}, lng=${lng})`);
}

export function registerIncidentSocket(io: Server): void {
  io.on('connection', (socket) => {
    const firebaseUid = socket.data['firebaseUid'] as string | undefined;
    console.log(`[WS] ✓ connected ${socket.id} uid=${firebaseUid ?? 'anon'}`);

    // Lima → autoridades y broadcast global
    void socket.join(LIMA_ROOM);

    // Si el handshake autenticó al usuario, suscribirlo al room privado
    // (auth.socket.ts dejó el uid decodificado en socket.data)
    if (firebaseUid) {
      void socket.join(userRoom(firebaseUid));
    }

    const { lat, lng } = socket.handshake.auth as { lat?: number; lng?: number };
    if (typeof lat === 'number' && typeof lng === 'number') {
      void joinRooms(socket, lat, lng);
    } else {
      console.warn(`[WS] ⚠ ${socket.id} NO mandó lat/lng en handshake — NO se une a prox room`);
    }

    socket.on('disconnect', (reason) => {
      console.log(`[WS] ✗ disconnect ${socket.id} reason=${reason}`);
    });

    // El cliente re-emite cuando el GPS detecta que cambió de zona
    socket.on('room:update', (payload: unknown) => {
      const { lat: newLat, lng: newLng } = (payload ?? {}) as { lat?: number; lng?: number };
      if (typeof newLat !== 'number' || typeof newLng !== 'number') return;
      void joinRooms(socket, newLat, newLng);
    });
  });

  // Incidente publicado → broadcast al distrito + Lima
  // (la exclusión del reporter solo aplica a push FCM, no al WS — el reporter
  //  igual quiere ver su pin aparecer en su propio mapa en tiempo real)
  eventBus.on(IncidentEvents.NEW, (payload: IncidentEventPayload) => {
    emitIncidentNew(io, payload.incident);
  });

  eventBus.on(IncidentEvents.UPDATED, (payload: IncidentEventPayload) => {
    emitIncidentUpdated(io, payload.incident);
  });

  // Primer reporte en una zona → mini-alert a usuarios cercanos (~1km)
  eventBus.on(IncidentEvents.CONFIRM_REQUEST, (payload: ConfirmRequestPayload) => {
    emitConfirmRequest(io, payload);
  });

  // Cambio de estado dirigido a los reportantes — actualiza "Mis reportes" en vivo
  eventBus.on(
    IncidentEvents.STATUS_CHANGED_FOR_REPORTERS,
    (payload: StatusChangedForReportersPayload) => {
      emitReportStatusChanged(io, payload);
    },
  );

  // Sesión de pánico → broadcast a autoridades en Lima (solo coordenadas)
  eventBus.on(PanicEvents.STARTED, (payload: PanicStartedPayload) => {
    io.to(LIMA_ROOM).emit('panic:started', payload);
  });

  eventBus.on(PanicEvents.STOPPED, (payload: PanicStoppedPayload) => {
    io.to(LIMA_ROOM).emit('panic:stopped', payload);
  });
}

export function emitIncidentNew(io: Server, incident: PublicIncidentDTO): void {
  io.to(districtRoom(incident.district)).to(LIMA_ROOM).emit('incident:new', incident);
}

export function emitIncidentUpdated(io: Server, incident: PublicIncidentDTO): void {
  io.to(districtRoom(incident.district)).to(LIMA_ROOM).emit('incident:updated', incident);
}

export function emitReportStatusChanged(
  io: Server,
  payload: StatusChangedForReportersPayload,
): void {
  const wireEvent = {
    incidentId: payload.incidentId,
    status: payload.status,
    feedback: payload.feedback,
    district: payload.district,
    type: payload.type,
    updatedAt: payload.updatedAt,
  };
  for (const uid of payload.firebaseUids) {
    io.to(userRoom(uid)).emit('report:status-changed', wireEvent);
  }
}

export function emitConfirmRequest(io: Server, payload: ConfirmRequestPayload): void {
  // Emitir al tile exacto Y a los 8 tiles vecinos (3×3 grid).
  // Con TILE_SIZE=0.003° (~330m), el grid 3×3 cubre máximo ~1km de radio desde
  // el centro del tile.
  // Privacidad: enviar coords aproximadas (redondeadas a 0.001° = ~100m).
  // Suficiente precisión para reverse-geocode "Av. Larco" sin pinpointing al reportante.
  const latT = tileIndex(payload.lat);
  const lngT = tileIndex(payload.lng);
  const approxLat = Math.round(payload.lat * 1000) / 1000;
  const approxLng = Math.round(payload.lng * 1000) / 1000;
  const message = {
    zoneLabel: payload.zoneLabel,
    type: payload.type,
    approxLat,
    approxLng,
    reportedAt: new Date().toISOString(),
  };

  console.log(
    `[WS] 📢 emitConfirmRequest origen=(${payload.lat}, ${payload.lng}) approx=(${approxLat}, ${approxLng}) tile=(${latT}, ${lngT}) zone=${payload.zoneLabel} type=${payload.type}`,
  );

  // Excluir al reporter del WS emit — no tiene sentido que confirme su propio reporte.
  const reporterRoom = payload.reporterUid ? userRoom(payload.reporterUid) : undefined;

  let totalRecipients = 0;
  const targetTiles: string[] = [];
  for (let dLat = -1; dLat <= 1; dLat++) {
    for (let dLng = -1; dLng <= 1; dLng++) {
      const room = `prox:${latT + dLat}:${lngT + dLng}`;
      targetTiles.push(room);
      const size = io.sockets.adapter.rooms.get(room)?.size ?? 0;
      totalRecipients += size;
      if (size > 0) console.log(`[WS]    → ${room} (${size} client${size === 1 ? '' : 's'})`);
      const emitter = reporterRoom ? io.to(room).except(reporterRoom) : io.to(room);
      emitter.emit('alert:confirm-request', message);
    }
  }
  console.log(`[WS] 📢 confirm-request emitido a ${totalRecipients} socket(s) en total`);

  // FCM push tile-filtered — alcanza a usuarios con app cerrada/background
  // que tienen su proxTile dentro del grid 3×3. Fire-and-forget.
  deviceTokenRepo
    .findByProxTiles(targetTiles)
    .then(async (entries) => {
      // Excluir token(s) del reporter para que no reciba su propia notificación.
      const filtered = payload.reporterUserId
        ? entries.filter((e) => e.userId !== payload.reporterUserId)
        : entries;
      if (filtered.length === 0) {
        console.log('[FCM] 0 device_tokens matching tiles — skip push');
        return;
      }
      const tokens = filtered.map((e) => e.token);
      console.log(`[FCM] 🔔 enviando confirm-request push a ${tokens.length} token(s)`);
      const result = await sendConfirmRequestPush(
        {
          zoneLabel: payload.zoneLabel,
          type: payload.type,
          approxLat,
          approxLng,
          reportedAt: message.reportedAt,
        },
        tokens,
        redis as Redis,
      );
      console.log(
        `[FCM] 📊 push result sent=${result.sent} cooldown=${result.skippedCooldown} failed=${result.failed}`,
      );
    })
    .catch((e) => console.error('[FCM] ⚠ push failed:', e));
}
