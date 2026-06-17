import "leaflet/dist/leaflet.css";
import { useState } from "react";
import { CircleMarker, MapContainer, TileLayer, Tooltip } from "react-leaflet";
import type {
  PanicSessionDTO,
  PublicIncidentDTO,
  Severity,
} from "../../../core/api/types";
import { incidentTypeLabel } from "../../incidents/presentation/utils/labels";
import { HeatmapLayer } from "./HeatmapLayer";

const LIMA_CENTER: [number, number] = [-12.046374, -77.042793];

const SEVERITY_HEX: Record<Severity, string> = {
  CRITICAL: "#ffb4ab",
  MODERATE: "#ffb955",
  LOW: "#22c55e",
};

interface IncidentsMapProps {
  incidents: PublicIncidentDTO[];
  panicSessions?: PanicSessionDTO[];
  onPinClick?: (id: string) => void;
  showHeatmap?: boolean;
}

const IncidentsMap = ({
  incidents,
  panicSessions = [],
  onPinClick,
  showHeatmap = true,
}: IncidentsMapProps) => {
  const [dark, setDark] = useState(false);
  return (
    <div className="relative h-full w-full">
      <MapContainer
        center={LIMA_CENTER}
        zoom={12}
        scrollWheelZoom
        className="h-full w-full"
        style={{ background: dark ? "#0b0e14" : "#f5f5f0" }}
      >
        <TileLayer
          attribution='&copy; <a href="https://carto.com/">CARTO</a>'
          url={
            dark
              ? "https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png"
              : "https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png"
          }
        />
        {showHeatmap && incidents.length > 1 && (
          <HeatmapLayer incidents={incidents} />
        )}
        {incidents.map((inc) => {
          const color = SEVERITY_HEX[inc.severity];
          return (
            <CircleMarker
              key={inc.id}
              center={[inc.lat, inc.lng]}
              radius={inc.severity === "CRITICAL" ? 10 : 7}
              pathOptions={{
                color: "#ffffff",
                weight: 2,
                fillColor: color,
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
                  <span className="text-stitch-on-surface-variant">
                    {inc.district}
                  </span>
                </div>
              </Tooltip>
            </CircleMarker>
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
              color: "#ff1744",
              weight: 2,
              fillColor: "#ff1744",
              fillOpacity: 0.2,
            }}
          />,
          // Punto central sólido con tooltip
          <CircleMarker
            key={`${session.id}-dot`}
            center={[session.lat, session.lng]}
            radius={9}
            pathOptions={{
              color: "#ffffff",
              weight: 2,
              fillColor: "#ff1744",
              fillOpacity: 0.95,
            }}
          >
            <Tooltip direction="top" offset={[0, -12]} opacity={1} permanent>
              <span style={{ fontWeight: 700, fontSize: 11, color: "#cc0000" }}>
                🚨 PÁNICO
              </span>
            </Tooltip>
          </CircleMarker>,
        ])}
      </MapContainer>
      <button
        onClick={() => setDark((v) => !v)}
        className="absolute top-4 right-4 z-[1000] w-9 h-9 flex items-center justify-center rounded-full border bg-white text-gray-700 shadow-md transition-colors hover:bg-gray-100"
        title={dark ? "Mapa claro" : "Mapa oscuro"}
        aria-label="Alternar estilo de mapa"
      >
        {dark ? "☀️" : "🌙"}
      </button>
    </div>
  );
};
export default IncidentsMap;
