import { useEffect } from 'react';
import { useMap } from 'react-leaflet';
import L from 'leaflet';
import 'leaflet.heat';

import type { PublicIncidentDTO, Severity } from '../../../core/api/types';

const HEAT_WEIGHT: Record<Severity, number> = {
  CRITICAL: 1.0,
  MODERATE: 0.7,
  LOW: 0.4,
};

const GRADIENT: Record<number, string> = {
  0.0: '#22c55e',
  0.3: '#8bc34a',
  0.5: '#F5A623',
  0.7: '#ff8a65',
  0.9: '#ef4444',
  1.0: '#dc2626',
};

interface Props {
  incidents: PublicIncidentDTO[];
}

export function HeatmapLayer({ incidents }: Props) {
  const map = useMap();

  useEffect(() => {
    if (incidents.length === 0) return;

    const points: Array<[number, number, number]> = incidents.map((inc) => [
      inc.lat,
      inc.lng,
      HEAT_WEIGHT[inc.severity],
    ]);

    const heat = L.heatLayer(points, {
      radius: 30,
      blur: 20,
      maxZoom: 14,
      max: 1.0,
      gradient: GRADIENT,
    });

    heat.addTo(map);

    return () => {
      map.removeLayer(heat);
    };
  }, [map, incidents]);

  return null;
}
