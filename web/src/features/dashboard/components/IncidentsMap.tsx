import { type FC, useState } from 'react';
import L from 'leaflet';
import { Moon, Sun } from 'lucide-react';
import { MapContainer, TileLayer, CircleMarker, Marker, Tooltip } from 'react-leaflet';
import 'leaflet/dist/leaflet.css';

import type { PublicIncidentDTO, PanicSessionDTO, Severity } from '../../../core/api/types';
import { colors } from '../../../core/constants/colors';
import { incidentTypeLabel } from '../../incidents/presentation/utils/labels';
import { HeatmapLayer } from './HeatmapLayer';

const LIMA_CENTER: [number, number] = [-12.046374, -77.042793];

const SEVERITY_HEX: Record<Severity, string> = {
  CRITICAL: colors.severityCritical,
  MODERATE: colors.severityModerate,
  LOW: colors.severityLow,
};

/** Marcador HTML: solo CRITICAL pulsa; el destacado aumenta de tamaño. */
function pulseIcon(severity: Severity, highlighted: boolean): L.DivIcon {
  const color = SEVERITY_HEX[severity];
  const classes = ['ay-pin', severity === 'CRITICAL' ? 'ay-pin--fast' : '', highlighted ? 'ay-pin--hl' : '']
    .filter(Boolean)
    .join(' ');
  const criticalPulse = severity === 'CRITICAL'
    ? '<span class="ay-pin__ping"></span>'
    : '';
  return L.divIcon({
    className: 'ay-pin-wrap',
    html: `<span class="${classes}" style="--ay-pin-c:${color}">
             ${criticalPulse}
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
  /** Muestra la capa de calor cuando hay más de un incidente. Default true. */
  showHeatmap?: boolean;
}

const TILE_THEME = {
  dark: {
    url: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
    bg: colors.bgDark2,
  },
  light: {
    url: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
    bg: colors.bgGray,
  },
} as const;

export const IncidentsMap: FC<Props> = ({
  incidents,
  panicSessions = [],
  onPinClick,
  theme = 'dark',
  center,
  zoom,
  highlightId,
  showHeatmap = true,
}) => {
  const [activeTheme, setActiveTheme] = useState<'dark' | 'light'>(theme);
  const tile = TILE_THEME[activeTheme];

  return (
    <div className="relative h-full w-full">
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
      {showHeatmap && incidents.length > 1 && (
        <HeatmapLayer incidents={incidents} />
      )}
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
            color:       colors.severityCritical,
            weight:      2,
            fillColor:   colors.severityCritical,
            fillOpacity: 0.20,
          }}
        />,
        // Punto central sólido con tooltip
        <CircleMarker
          key={`${session.id}-dot`}
          center={[session.lat, session.lng]}
          radius={9}
          pathOptions={{
            color:       colors.textWhite,
            weight:      2,
            fillColor:   colors.severityCritical,
            fillOpacity: 0.95,
          }}
        >
          <Tooltip direction="top" offset={[0, -12]} opacity={1} permanent>
            <span style={{ fontWeight: 700, fontSize: 11, color: colors.severityCritical }}>PÁNICO</span>
          </Tooltip>
        </CircleMarker>,
      ])}
      </MapContainer>

      <button
        type="button"
        onClick={() => setActiveTheme((current) => current === 'dark' ? 'light' : 'dark')}
        className="absolute right-4 top-4 z-[1000] flex h-11 w-11 items-center justify-center rounded-full border border-stitch-outline-variant bg-stitch-surface-container text-stitch-on-surface transition-colors hover:bg-stitch-surface-container-high"
        title={activeTheme === 'dark' ? 'Usar mapa claro' : 'Usar mapa oscuro'}
        aria-label={activeTheme === 'dark' ? 'Usar mapa claro' : 'Usar mapa oscuro'}
      >
        {activeTheme === 'dark' ? <Sun size={18} /> : <Moon size={18} />}
      </button>
    </div>
  );
};
