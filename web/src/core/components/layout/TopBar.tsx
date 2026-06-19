import { useRouterState } from "@tanstack/react-router";
import { useEffect, useState } from "react";

import { getLastRefreshAt, subscribeToRefresh } from "../../lib/refresh-signal";

const ROUTE_LABELS: Record<string, string> = {
  "/dashboard": "Mapa en Vivo",
  "/incidents": "Incidentes",
  "/predictions": "Predicciones IA",
  "/statistics": "Estadísticas",
  "/export": "Exportar",
  "/admin/users": "Administrar Autoridades",
};

function getCurrentLabel(pathname: string): string {
  if (pathname.startsWith("/incidents/")) return "Detalle de incidente";
  return ROUTE_LABELS[pathname] ?? "Panel";
}

function elapsed(since: Date): number {
  return Math.floor((Date.now() - since.getTime()) / 1000);
}

interface TopBarProps {
  onMenuClick: () => void;
}

const TopBar = ({ onMenuClick }: TopBarProps) => {
  const routerState = useRouterState();
  const [secondsAgo, setSecondsAgo] = useState(() => elapsed(getLastRefreshAt()));

  // Tick every second
  useEffect(() => {
    const interval = setInterval(
      () => setSecondsAgo(elapsed(getLastRefreshAt())),
      1000,
    );
    return () => clearInterval(interval);
  }, []);

  // Reset display immediately when new live data arrives
  useEffect(() => {
    return subscribeToRefresh(() => setSecondsAgo(0));
  }, []);

  const pathname = routerState.location.pathname;
  const label = getCurrentLabel(pathname);
  const isHistorical = pathname === "/statistics";

  return (
    <header className="h-16 flex justify-between items-center px-4 md:px-8 w-full bg-stitch-surface-container/70 backdrop-blur-xl z-40 shrink-0 gap-3">
      <div className="flex items-center gap-3 min-w-0">
        <button
          onClick={onMenuClick}
          className="lg:hidden p-1.5 text-stitch-on-surface-variant hover:text-white transition-colors shrink-0"
          aria-label="Abrir menú"
        >
          <span className="material-symbols-outlined">menu</span>
        </button>
        <h1 className="text-base md:text-lg font-black text-white font-headline uppercase tracking-tight truncate">
          {label}
        </h1>
        {isHistorical ? (
          <div className="hidden sm:flex items-center gap-2 px-3 py-1 bg-stitch-surface-container-low rounded-full shrink-0">
            <span className="w-2 h-2 rounded-full bg-stitch-tertiary" />
            <span className="text-[10px] font-bold text-stitch-on-surface uppercase tracking-widest font-label">
              Histórico · DataCrim 2017–2020
            </span>
          </div>
        ) : (
          <div className="flex items-center gap-2 px-3 py-1 bg-stitch-surface-container-low rounded-full shrink-0">
            <span className="w-2 h-2 rounded-full bg-green-500 pulse-live" />
            <span className="hidden sm:inline text-[10px] font-bold text-stitch-on-surface uppercase tracking-widest font-label">
              En vivo · Actualizado hace {secondsAgo}s
            </span>
          </div>
        )}
      </div>

      <div className="hidden xl:flex items-center gap-6 shrink-0">
        <div className="flex items-center gap-2 bg-stitch-surface-container-high/50 px-4 py-1.5 rounded-lg cursor-not-allowed opacity-60">
          <span className="material-symbols-outlined text-sm text-stitch-on-surface-variant">
            filter_list
          </span>
          <span className="text-xs font-bold text-stitch-on-surface font-label uppercase">
            Lima · Todos los distritos
          </span>
          <span className="material-symbols-outlined text-sm text-stitch-on-surface-variant">
            keyboard_arrow_down
          </span>
        </div>
      </div>
    </header>
  );
};

export default TopBar;
