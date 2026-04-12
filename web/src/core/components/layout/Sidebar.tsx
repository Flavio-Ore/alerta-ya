import { FC } from 'react';
import { Link, useNavigate } from '@tanstack/react-router';
import { Map, List, Brain, BarChart2, Download, LogOut } from 'lucide-react';

/**
 * Sidebar de navegación — panel autoridades.
 * Specs: 240px fijo, fondo #141720, borde derecho #2D3A4A.
 * Ítem activo: border-left 3px #1B3A6B + bg #1B3A6B15.
 */
export const Sidebar: FC = () => {
  const navigate = useNavigate();

  const navItems = [
    { to: '/dashboard'   as const, label: 'Mapa en Vivo',   icon: Map },
    { to: '/incidents'   as const, label: 'Incidentes',      icon: List },
    { to: '/predictions' as const, label: 'Predicciones IA', icon: Brain },
    { to: '/statistics'  as const, label: 'Estadísticas',    icon: BarChart2 },
  ];

  return (
    <aside
      className="flex flex-col w-60 shrink-0 bg-ay-bg-dark2 border-r border-ay-border/20"
      style={{ borderRightWidth: '0.5px', borderColor: '#2D3A4A' }}
    >
      {/* Logo */}
      <div className="flex items-center px-5 py-5">
        <img
          src="/assets/logo/alertaya-logo-dark.svg"
          alt="AlertaYa"
          style={{ height: 32 }}
        />
      </div>

      <div className="mx-4 mb-3" style={{ borderTop: '0.5px solid #2D3A4A' }} />

      {/* Nav principal */}
      <nav className="flex-1 px-2 space-y-0.5">
        {navItems.map(({ to, label, icon: Icon }) => (
          <Link
            key={to}
            to={to}
            className="flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm transition-colors text-ay-text-sec hover:bg-ay-primary/5"
            activeProps={{
              className: 'flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm transition-colors text-white border-l-[3px] border-ay-primary bg-ay-primary/10 pl-[9px]',
            }}
          >
            <Icon size={18} />
            <span>{label}</span>
          </Link>
        ))}
      </nav>

      {/* Exportar — separado porque es acción */}
      <div className="px-2 pb-2">
        <div className="mb-1" style={{ borderTop: '0.5px solid #2D3A4A' }} />
        <Link
          to="/export"
          className="flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm transition-colors text-ay-text-sec hover:bg-ay-primary/5"
          activeProps={{
            className: 'flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm transition-colors text-white border-l-[3px] border-ay-primary bg-ay-primary/10 pl-[9px]',
          }}
        >
          <Download size={18} />
          <span>Exportar</span>
        </Link>
      </div>

      {/* Cerrar sesión */}
      <div className="px-2 pb-4">
        <button
          onClick={() => {
            // TODO(auth): implementar logout Firebase
            navigate({ to: '/auth/login' });
          }}
          className="flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm w-full transition-colors"
          style={{ color: '#EF444466' }}
        >
          <LogOut size={18} />
          <span>Cerrar sesión</span>
        </button>
      </div>
    </aside>
  );
};
