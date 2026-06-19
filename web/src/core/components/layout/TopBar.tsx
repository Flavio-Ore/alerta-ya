import { useRouterState } from "@tanstack/react-router";
import { useEffect, useState } from "react";

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

const TopBar = () => {
  const routerState = useRouterState();
  const [secondsAgo, setSecondsAgo] = useState(0);

  useEffect(() => {
    setSecondsAgo(0);
  }, [routerState.location.pathname]);

  useEffect(() => {
    const interval = setInterval(() => setSecondsAgo((s) => s + 1), 1000);
    return () => clearInterval(interval);
  }, []);

  const label = getCurrentLabel(routerState.location.pathname);

  return (
    <header className="h-16 flex justify-between items-center px-8 w-full bg-stitch-surface-container/70 backdrop-blur-xl z-40 shrink-0">
      <div className="flex items-center gap-6">
        <h1 className="text-lg font-black text-white font-headline uppercase tracking-tight">
          {label}
        </h1>
        <div className="flex items-center gap-2 px-3 py-1 bg-stitch-surface-container-low rounded-full">
          <span className="w-2 h-2 rounded-full bg-green-500 pulse-live" />
          <span className="text-[10px] font-bold text-stitch-on-surface uppercase tracking-widest font-label">
            En vivo · Actualizado hace {secondsAgo}s
          </span>
        </div>
      </div>

      <div className="flex items-center gap-6">
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
