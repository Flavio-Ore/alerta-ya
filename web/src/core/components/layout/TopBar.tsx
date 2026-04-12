import { FC, useEffect, useState } from 'react';
import { useRouterState } from '@tanstack/react-router';
import { Bell } from 'lucide-react';

const ROUTE_LABELS: Record<string, string> = {
  '/dashboard':   'Mapa en Vivo',
  '/incidents':   'Incidentes',
  '/predictions': 'Predicciones IA',
  '/statistics':  'Estadísticas',
  '/export':      'Exportar',
};

/**
 * Top bar del panel de autoridades.
 * Fondo: #1A1D23, altura: 60px.
 * Centro: indicador "En vivo" con dot verde pulsante.
 */
export const TopBar: FC = () => {
  const routerState = useRouterState();
  const [secondsAgo, setSecondsAgo] = useState(0);

  useEffect(() => {
    setSecondsAgo(0);
  }, [routerState.location.pathname]);

  useEffect(() => {
    const interval = setInterval(() => setSecondsAgo((s) => s + 1), 1000);
    return () => clearInterval(interval);
  }, []);

  const currentLabel = ROUTE_LABELS[routerState.location.pathname] ?? 'Panel';

  return (
    <header
      className="flex items-center justify-between px-6 shrink-0"
      style={{
        height: 60,
        backgroundColor: '#1A1D23',
        borderBottom: '0.5px solid #2D3A4A',
      }}
    >
      <span className="text-sm font-semibold text-white">{currentLabel}</span>

      <div className="flex items-center gap-2">
        <span
          className="inline-block w-2 h-2 rounded-full bg-[#22C55E] animate-pulse"
          aria-hidden="true"
        />
        <span className="text-xs text-ay-text-sec">
          En vivo · Actualizado hace {secondsAgo}s
        </span>
      </div>

      <div className="flex items-center gap-3">
        <button
          className="relative p-2 rounded-lg text-ay-text-sec hover:text-white hover:bg-ay-primary/10 transition-colors"
          aria-label="Notificaciones"
        >
          <Bell size={20} />
          <span className="absolute top-1 right-1 w-2 h-2 rounded-full bg-ay-critical" />
        </button>
        <div
          className="w-8 h-8 rounded-full bg-ay-primary flex items-center justify-center text-white text-xs font-bold"
          aria-label="Supervisor"
        >
          S
        </div>
      </div>
    </header>
  );
};
