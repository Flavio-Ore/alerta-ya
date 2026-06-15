import { FC } from 'react';
import { MapContainer, TileLayer, CircleMarker, Tooltip } from 'react-leaflet';
import 'leaflet/dist/leaflet.css';

const LIMA_CENTER: [number, number] = [-12.046374, -77.042793];

export interface RiskZone {
  lat:      number;
  lng:      number;
  risk:     number;   // 0–100 (percentile-rank del conteo histórico)
  count:    number;
  district: string;
}

/** Escala de color del riesgo: verde (bajo) → ámbar → rojo (crítico). */
export function riskColor(r: number): string {
  if (r >= 80) return '#ef4444'; // rojo
  if (r >= 60) return '#f97316'; // naranja
  if (r >= 40) return '#f59e0b'; // ámbar
  if (r >= 20) return '#a3e635'; // lima
  return '#22c55e';              // verde
}

/**
 * Mapa de calor de riesgo histórico (tema claro).
 * Cada zona es un círculo coloreado por su nivel de riesgo.
 */
export const RiskHeatMap: FC<{ zones: RiskZone[] }> = ({ zones }) => (
  <MapContainer
    center={LIMA_CENTER}
    zoom={11}
    scrollWheelZoom
    className="h-full w-full"
    style={{ background: '#e2e8f0' }}
  >
    <TileLayer
      attribution='&copy; <a href="https://carto.com/">CARTO</a> · datos: DataCrim (INEI)'
      url="https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png"
    />
    {zones.map((z, i) => (
      <CircleMarker
        key={i}
        center={[z.lat, z.lng]}
        radius={5}
        pathOptions={{
          weight:      0,
          fillColor:   riskColor(z.risk),
          fillOpacity: 0.55,
        }}
      >
        <Tooltip direction="top" opacity={1}>
          <div className="text-[11px] font-bold">
            {z.district}
            <br />
            <span className="font-normal">Riesgo {z.risk} · {z.count} casos</span>
          </div>
        </Tooltip>
      </CircleMarker>
    ))}
  </MapContainer>
);
