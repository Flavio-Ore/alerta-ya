import { EventEmitter } from 'events';

export const eventBus = new EventEmitter();

export const IncidentEvents = {
  NEW: 'incident.new',
  UPDATED: 'incident.updated',
  CONFIRM_REQUEST: 'incident.confirm-request', // mini-alert al primer reporte
} as const;

export interface ConfirmRequestPayload {
  zoneLabel: string;   // "Av. El Sol, San Juan de Lurigancho"
  type: string;        // "ROBBERY"
  lat: number;
  lng: number;
}
