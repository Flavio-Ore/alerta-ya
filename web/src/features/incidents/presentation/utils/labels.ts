import type { IncidentType, Severity, IncidentStatus } from '../../../../core/api/types';

export const incidentTypeLabel: Record<IncidentType, string> = {
  ROBBERY:    'Robo',
  ACCIDENT:   'Accidente',
  HARASSMENT: 'Acoso',
  EXTORTION:  'Extorsión',
  SUSPICIOUS: 'Actividad sospechosa',
};

export const severityLabel: Record<Severity, string> = {
  LOW:      'Bajo',
  MODERATE: 'Moderado',
  CRITICAL: 'Crítico',
};

export const severityClass: Record<Severity, { text: string; bg: string; border: string; bar: string }> = {
  LOW:      { text: 'text-ay-low',      bg: 'bg-ay-low/10',      border: 'border-ay-low/30',      bar: 'border-ay-low' },
  MODERATE: { text: 'text-ay-moderate', bg: 'bg-ay-moderate/10', border: 'border-ay-moderate/30', bar: 'border-ay-moderate' },
  CRITICAL: { text: 'text-ay-critical', bg: 'bg-ay-critical/10', border: 'border-ay-critical/30', bar: 'border-ay-critical' },
};

export const statusLabel: Record<IncidentStatus, string> = {
  ACTIVE:       'Activo',
  IN_ATTENTION: 'En atención',
  CLOSED:       'Cerrado',
};

export const statusClass: Record<IncidentStatus, { text: string; bg: string; border: string }> = {
  ACTIVE:       { text: 'text-ay-critical', bg: 'bg-ay-critical/10', border: 'border-ay-critical/30' },
  IN_ATTENTION: { text: 'text-ay-primary',  bg: 'bg-ay-primary/10',  border: 'border-ay-primary/30'  },
  CLOSED:       { text: 'text-ay-low',      bg: 'bg-ay-low/10',      border: 'border-ay-low/30'      },
};

export function formatRelativeTime(iso: string): string {
  const diffMs = Date.now() - new Date(iso).getTime();
  const minutes = Math.floor(diffMs / 60_000);
  if (minutes < 1)  return 'recién';
  if (minutes < 60) return `hace ${minutes} min`;
  const hours = Math.floor(minutes / 60);
  if (hours < 24)   return `hace ${hours} h`;
  const days = Math.floor(hours / 24);
  return `hace ${days} d`;
}

export function formatHHMM(iso: string): string {
  return new Date(iso).toLocaleTimeString('es-PE', {
    hour:   '2-digit',
    minute: '2-digit',
    hour12: false,
  });
}
