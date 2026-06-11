import { FC } from "react";
import { Link, useNavigate } from "@tanstack/react-router";

import { useAuthStore } from "../../../features/auth/presentation/stores/auth.store";

interface NavItem {
  to: "/dashboard" | "/incidents" | "/predictions" | "/statistics" | "/export" | "/admin/users";
  label: string;
  icon: string;
}

const NAV_ITEMS: NavItem[] = [
  { to: "/dashboard", label: "Mapa en Vivo", icon: "map" },
  { to: "/incidents", label: "Incidentes", icon: "assignment_late" },
  { to: "/predictions", label: "Predicciones IA", icon: "psychology" },
  { to: "/statistics", label: "Estadísticas", icon: "bar_chart" },
  { to: "/export", label: "Exportar", icon: "ios_share" },
];

const ADMIN_NAV_ITEM: NavItem = { to: "/admin/users", label: "Administrar Autoridades", icon: "badge" };

function getInitials(email: string, displayName: string | null): string {
  if (displayName) {
    return displayName
      .split(" ")
      .map((p) => p[0])
      .slice(0, 2)
      .join("")
      .toUpperCase();
  }
  return email.slice(0, 2).toUpperCase();
}

export const Sidebar: FC = () => {
  const user = useAuthStore((s) => s.user);
  const signOut = useAuthStore((s) => s.signOut);
  const navigate = useNavigate();

  async function handleSignOut() {
    try {
      await signOut();
    } finally {
      // Navegar SIEMPRE — incluso si signOut tira (Firebase desconectado, etc.)
      // Force replace para evitar que el user vuelva con el back del browser
      await navigate({ to: "/auth/login", replace: true });
    }
  }

  return (
    <aside className="h-screen w-64 shrink-0 flex flex-col py-6 bg-stitch-surface-container-low z-50">
      {/* Logo — variante dark del SVG (azules → blanco, ámbar intacto) */}
      <div className="px-6 mb-10 flex items-center">
        <img
          src="/assets/logo/alertaya-logo-horizontal-dark.svg"
          alt="AlertaYa"
          className="h-8 w-auto"
        />
      </div>

      {/* Nav principal */}
      <nav className="flex-1 px-3 space-y-1">
        {NAV_ITEMS.map(({ to, label, icon }) => (
          <Link
            key={to}
            to={to}
            className="flex items-center gap-3 px-3 py-3 rounded-lg text-stitch-on-surface-variant hover:text-white hover:bg-stitch-surface-container/60 transition-colors"
            activeProps={{
              className:
                "flex items-center gap-3 px-3 py-3 rounded-lg text-stitch-primary font-bold border-r-2 border-stitch-primary bg-stitch-surface-container/40 transition-colors",
            }}
          >
            <span className="material-symbols-outlined">{icon}</span>
            <span className="font-label text-sm">{label}</span>
          </Link>
        ))}
      </nav>

      {/* Admin section — solo visible para ADMIN */}
      {user?.role === 'ADMIN' && (
        <div className="px-3 mb-2">
          <div className="h-px bg-stitch-surface-container-high mb-2" />
          <Link
            to={ADMIN_NAV_ITEM.to}
            className="flex items-center gap-3 px-3 py-3 rounded-lg text-stitch-on-surface-variant hover:text-white hover:bg-stitch-surface-container/60 transition-colors"
            activeProps={{
              className:
                "flex items-center gap-3 px-3 py-3 rounded-lg text-stitch-primary font-bold border-r-2 border-stitch-primary bg-stitch-surface-container/40 transition-colors",
            }}
          >
            <span className="material-symbols-outlined">{ADMIN_NAV_ITEM.icon}</span>
            <span className="font-label text-sm">{ADMIN_NAV_ITEM.label}</span>
          </Link>
        </div>
      )}

      {/* User card + settings */}
      <div className="px-3 pt-6 space-y-1">
        <button
          onClick={handleSignOut}
          className="w-full flex items-center gap-3 px-3 py-3 rounded-lg text-stitch-on-surface-variant hover:text-white hover:bg-stitch-surface-container/60 transition-colors"
        >
          <span className="material-symbols-outlined">logout</span>
          <span className="font-label text-sm">Cerrar sesión</span>
        </button>

        {user && (
          <div className="mt-4 p-3 rounded-xl bg-stitch-surface-container-low flex items-center gap-3">
            <div className="w-10 h-10 rounded-full bg-stitch-primary-container flex items-center justify-center text-stitch-primary font-bold">
              {getInitials(user.email, user.displayName)}
            </div>
            <div className="overflow-hidden">
              <p className="text-sm font-bold text-white truncate">
                {user.displayName ?? user.email.split("@")[0]}
              </p>
              <p className="text-[10px] text-stitch-on-surface-variant uppercase tracking-wider font-bold">
                {user.role === "ADMIN" ? "Administrador" : "Autoridad"}
              </p>
            </div>
          </div>
        )}
      </div>
    </aside>
  );
};
