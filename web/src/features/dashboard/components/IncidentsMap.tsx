import { FC } from 'react';
import L from 'leaflet';
import { MapContainer, TileLayer, CircleMarker, Marker, Tooltip } from 'react-leaflet';
import 'leaflet/dist/leaflet.css';

import type { PublicIncidentDTO, PanicSessionDTO, Severity } from '../../../core/api/types';
import { incidentTypeLabel } from '../../incidents/presentation/utils/labels';

const LIMA_CENTER: [number, number] = [-12.046374, -77.042793];

// Colores vibrantes y saturados — resaltan tanto sobre tiles claros como oscuros.
const SEVERITY_HEX: Record<Severity, string> = {
  CRITICAL: '#ef4444',
  MODERATE: '#f59e0b',
  LOW:      '#22c55e',
};

// Velocidad del pulso por severidad: crítico late rápido, leve lento.
const SEVERITY_SPEED: Record<Severity, string> = {
  CRITICAL: 'ay-pin--fast',
  MODERATE: '',
  LOW:      'ay-pin--slow',
};

/** Marcador HTML con anillo pulsante. divIcon permite animar con CSS (CircleMarker no). */
function pulseIcon(severity: Severity, highlighted: boolean): L.DivIcon {
  const color = SEVERITY_HEX[severity];
  const classes = ['ay-pin', SEVERITY_SPEED[severity], highlighted ? 'ay-pin--hl' : '']
    .filter(Boolean)
    .join(' ');
  return L.divIcon({
    className: 'ay-pin-wrap',
    html: `<span class="${classes}" style="--ay-pin-c:${color}">
             <span class="ay-pin__ping"></span>
             <span class="ay-pin__dot"></span>
           </span>`,
    iconSize:   [44, 44],
    iconAnchor: [22, 22],
  });
}

interface Props {
  incidents: PublicIncidentDTO[];
  panicSessions?: PanicSessionDTO[];
  onPinClick?: (id: string) => void;
  /** Tema del basemap. 'dark' (default) para el dashboard, 'light' para el detalle. */
  theme?: 'dark' | 'light';
  /** Centro inicial del mapa. Si se omite, usa el centro de Lima. */
  center?: [number, number];
  /** Zoom inicial. Default 12. */
  zoom?: number;
  /** Id del incidente a destacar: halo + punto grande + tooltip permanente. */
  highlightId?: string;
}

const TILE_THEME = {
  dark:  { url: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',  bg: '#0b0e14' },
  light: { url: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png', bg: '#e2e8f0' },
} as const;

export const IncidentsMap: FC<Props> = ({
  incidents,
  panicSessions = [],
  onPinClick,
  theme = 'dark',
  center,
  zoom,
  highlightId,
}) => {
  const tile = TILE_THEME[theme];
  return (
    <MapContainer
      center={center ?? LIMA_CENTER}
      zoom={zoom ?? 12}
      scrollWheelZoom
      className="h-full w-full"
      style={{ background: tile.bg }}
    >
      <TileLayer
        attribution='&copy; <a href="https://carto.com/">CARTO</a>'
        url={tile.url}
      />
      {incidents.map((inc) => {
        const color = SEVERITY_HEX[inc.severity];
        const highlighted = inc.id === highlightId;
        return (
          <Marker
            key={inc.id}
            position={[inc.lat, inc.lng]}
            icon={pulseIcon(inc.severity, highlighted)}
            eventHandlers={{ click: () => onPinClick?.(inc.id) }}
          >
            <Tooltip
              direction="top"
              offset={[0, highlighted ? -16 : -12]}
              opacity={1}
              permanent={highlighted}
            >
              <div className="text-[11px] font-bold text-slate-800">
                <span style={{ color }}>●</span> {incidentTypeLabel[inc.type]}
                <br />
                <span className="text-slate-500 font-medium">{inc.district}</span>
              </div>
            </Tooltip>
          </Marker>
        );
      })}

      {/* Sesiones de pánico activas — doble anillo para efecto pulsante */}
      {panicSessions.flatMap((session) => [
        // Anillo exterior translúcido
        <CircleMarker
          key={`${session.id}-ring`}
          center={[session.lat, session.lng]}
          radius={18}
          pathOptions={{
            color:       '#ff1744',
            weight:      2,
            fillColor:   '#ff1744',
            fillOpacity: 0.20,
          }}
        />,
        // Punto central sólido con tooltip
        <CircleMarker
          key={`${session.id}-dot`}
          center={[session.lat, session.lng]}
          radius={9}
          pathOptions={{
            color:       '#ffffff',
            weight:      2,
            fillColor:   '#ff1744',
            fillOpacity: 0.95,
          }}
        >
          <Tooltip direction="top" offset={[0, -12]} opacity={1} permanent>
            <span style={{ fontWeight: 700, fontSize: 11, color: '#cc0000' }}>🚨 PÁNICO</span>
          </Tooltip>
        </CircleMarker>,
      ])}
    </MapContainer>
  );
};
