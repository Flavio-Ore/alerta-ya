import { FC } from 'react';
import { MapContainer, TileLayer, CircleMarker, Tooltip } from 'react-leaflet';
import 'leaflet/dist/leaflet.css';

import type { PublicIncidentDTO, Severity } from '../../../core/api/types';
import { incidentTypeLabel } from '../../incidents/presentation/utils/labels';

const LIMA_CENTER: [number, number] = [-12.046374, -77.042793];

const SEVERITY_HEX: Record<Severity, string> = {
  CRITICAL: '#ffb4ab',
  MODERATE: '#ffb955',
  LOW:      '#22c55e',
};

interface Props {
  incidents: PublicIncidentDTO[];
  onPinClick?: (id: string) => void;
}

export const IncidentsMap: FC<Props> = ({ incidents, onPinClick }) => {
  return (
    <MapContainer
      center={LIMA_CENTER}
      zoom={12}
      scrollWheelZoom
      className="h-full w-full"
      style={{ background: '#0b0e14' }}
    >
      <TileLayer
        attribution='&copy; <a href="https://carto.com/">CARTO</a>'
        url="https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png"
      />
      {incidents.map((inc) => {
        const color = SEVERITY_HEX[inc.severity];
        return (
          <CircleMarker
            key={inc.id}
            center={[inc.lat, inc.lng]}
            radius={inc.severity === 'CRITICAL' ? 10 : 7}
            pathOptions={{
              color:       '#ffffff',
              weight:      2,
              fillColor:   color,
              fillOpacity: 0.85,
            }}
            eventHandlers={{
              click: () => onPinClick?.(inc.id),
            }}
          >
            <Tooltip direction="top" offset={[0, -8]} opacity={1}>
              <div className="text-[11px] font-bold">
                {incidentTypeLabel[inc.type]}
                <br />
                <span className="text-stitch-on-surface-variant">{inc.district}</span>
              </div>
            </Tooltip>
          </CircleMarker>
        );
      })}
    </MapContainer>
  );
};
