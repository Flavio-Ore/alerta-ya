import { EventEmitter } from 'events';

export const eventBus = new EventEmitter();

export const IncidentEvents = {
  NEW: 'incident.new',
  UPDATED: 'incident.updated',
  CONFIRM_REQUEST: 'incident.confirm-request', // mini-alert al primer reporte
  /** Cambio de estado dirigido a los reportantes del incidente */
  STATUS_CHANGED_FOR_REPORTERS: 'incident.status-changed-for-reporters',
} as const;

export const PanicEvents = {
  STARTED: 'panic.started',
  STOPPED: 'panic.stopped',
} as const;

/** Solo coordenadas — nunca exponer userId ni identidad del ciudadano */
export interface PanicStartedPayload {
  id: string;
  lat: number;
  lng: number;
  startedAt: string; // ISO
}

export interface PanicStoppedPayload {
  id: string;
}

export interface ConfirmRequestPayload {
  zoneLabel: string;   // "Av. El Sol, San Juan de Lurigancho"
  type: string;        // "ROBBERY"
  lat: number;
  lng: number;
  /** userId del reportante — para excluirlo de la notificación */
  reporterUserId?: string;
}

/** Payload del evento NEW/UPDATED — incluye reporter para exclusión de notif */
export interface IncidentEventPayload {
  incident: import("../../features/incidents/domain/entities/incident.entity").PublicIncidentDTO;
  /** userId del reportante que generó este evento — para excluirlo de la notif */
  reporterUserId?: string;
}

/** Payload del evento dirigido a los reportantes — emitido al room user:{firebaseUid} */
export interface StatusChangedForReportersPayload {
  /** Lista única de firebaseUids de los usuarios que reportaron este incidente */
  firebaseUids: string[];
  incidentId: string;
  status: string;       // IncidentStatus
  feedback: string | null;
  district: string;
  type: string;         // IncidentType
  updatedAt: string;    // ISO
}
