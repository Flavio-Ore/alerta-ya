import { Server, Socket } from 'socket.io';

import { eventBus, IncidentEvents, ConfirmRequestPayload } from '../core/events/event-bus';
import { getDistrict } from '../core/utils/geo.utils';
import { PublicIncidentDTO } from '../features/incidents/domain/entities/incident.entity';

const LIMA_ROOM = 'Lima';

// Room por distrito — para incidentes publicados
function districtRoom(district: string): string {
  return `district:${district}`;
}

// Room de proximidad ~1km — para mini-alerts
// Redondear a 2 decimales: 0.01° ≈ 1.1km en Lima
function proximityRoom(lat: number, lng: number): string {
  const bLat = Math.round(lat * 100) / 100;
  const bLng = Math.round(lng * 100) / 100;
  return `prox:${bLat}:${bLng}`;
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
  await socket.join(districtRoom(district));
  await socket.join(proximityRoom(lat, lng));
}

export function registerIncidentSocket(io: Server): void {
  io.on('connection', (socket) => {
    // Lima → autoridades y broadcast global
    void socket.join(LIMA_ROOM);

    const { lat, lng } = socket.handshake.auth as { lat?: number; lng?: number };
    if (typeof lat === 'number' && typeof lng === 'number') {
      void joinRooms(socket, lat, lng);
    }

    // El cliente re-emite cuando el GPS detecta que cambió de zona
    socket.on('room:update', (payload: unknown) => {
      const { lat: newLat, lng: newLng } = (payload ?? {}) as { lat?: number; lng?: number };
      if (typeof newLat !== 'number' || typeof newLng !== 'number') return;
      void joinRooms(socket, newLat, newLng);
    });
  });

  // Incidente publicado → broadcast al distrito + Lima
  eventBus.on(IncidentEvents.NEW, (incident: PublicIncidentDTO) => {
    emitIncidentNew(io, incident);
  });

  eventBus.on(IncidentEvents.UPDATED, (incident: PublicIncidentDTO) => {
    emitIncidentUpdated(io, incident);
  });

  // Primer reporte en una zona → mini-alert a usuarios cercanos (~1km)
  eventBus.on(IncidentEvents.CONFIRM_REQUEST, (payload: ConfirmRequestPayload) => {
    emitConfirmRequest(io, payload);
  });
}

export function emitIncidentNew(io: Server, incident: PublicIncidentDTO): void {
  io.to(districtRoom(incident.district)).to(LIMA_ROOM).emit('incident:new', incident);
}

export function emitIncidentUpdated(io: Server, incident: PublicIncidentDTO): void {
  io.to(districtRoom(incident.district)).to(LIMA_ROOM).emit('incident:updated', incident);
}

export function emitConfirmRequest(io: Server, payload: ConfirmRequestPayload): void {
  // Solo a usuarios dentro del proximity room (~1km) — no al distrito completo
  io.to(proximityRoom(payload.lat, payload.lng)).emit('alert:confirm-request', {
    zoneLabel: payload.zoneLabel,
    type: payload.type,
  });
  // Nunca emitir lat/lng exacta al cliente — solo la etiqueta de zona
}
