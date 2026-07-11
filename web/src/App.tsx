import {
  createRootRoute,
  createRoute,
  createRouter,
  Outlet,
  redirect,
  RouterProvider,
} from "@tanstack/react-router";
import { useEffect, useState } from "react";
import { Sidebar } from "./core/components/layout/Sidebar";
import TopBar from "./core/components/layout/TopBar";
import AdminUsersPage from "./features/admin/pages/AdminUsersPage";
import LoginPage from "./features/auth/presentation/pages/LoginPage";
import { useAuthStore } from "./features/auth/presentation/stores/auth.store";
import DashboardPage from "./features/dashboard/pages/DashboardPage";
import ExportPage from "./features/export/pages/ExportPage";
import IncidentDetailPage from "./features/incidents/pages/IncidentDetailPage";
import IncidentsListPage from "./features/incidents/pages/IncidentsListPage";
import PanicSessionsListPage from "./features/panic/pages/PanicSessionsListPage";
import PanicSessionDetailPage from "./features/panic/pages/PanicSessionDetailPage";
import PredictionsPage from "./features/predictions/pages/PredictionsPage";
import type { PanicSessionSummaryDTO } from "./core/api/types";
import StatisticsPage from "./features/statistics/pages/StatisticsPage";

function isAuthorized() {
  const user = useAuthStore.getState().user;
  return user !== null && (user.role === "AUTHORITY" || user.role === "ADMIN");
}

function AuthLayout() {
  const [sidebarOpen, setSidebarOpen] = useState(false);

  return (
    <div className="flex h-screen bg-stitch-surface overflow-hidden">
      {/* Backdrop — solo mobile, cierra sidebar al tocar fuera */}
      {sidebarOpen && (
        <div
          className="fixed inset-0 bg-black/60 z-40 lg:hidden"
          onClick={() => setSidebarOpen(false)}
        />
      )}
      <Sidebar open={sidebarOpen} onClose={() => setSidebarOpen(false)} />
      <div className="flex flex-col flex-1 overflow-hidden min-w-0">
        <TopBar onMenuClick={() => setSidebarOpen((v) => !v)} />
        <main className="flex-1 overflow-hidden flex flex-col">
          <Outlet />
        </main>
      </div>
    </div>
  );
}

const rootRoute = createRootRoute({
  beforeLoad: async ({ location }) => {
    // Esperá al bootstrap de Firebase antes de redirigir
    if (!useAuthStore.getState().isReady) {
      await new Promise<void>((resolve) => {
        const unsub = useAuthStore.subscribe((s) => {
          if (s.isReady) {
            unsub();
            resolve();
          }
        });
      });
    }

    if (location.pathname === "/" && !isAuthorized()) {
      throw redirect({ to: "/auth/login" });
    }
    if (location.pathname === "/" && isAuthorized()) {
      throw redirect({ to: "/dashboard" });
    }
  },
});

const loginRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: "/auth/login",
  component: LoginPage,
  beforeLoad: () => {
    if (isAuthorized()) {
      throw redirect({ to: "/dashboard" });
    }
  },
});

const authLayoutRoute = createRoute({
  getParentRoute: () => rootRoute,
  id: "auth",
  component: AuthLayout,
  beforeLoad: ({ location }) => {
    if (!isAuthorized()) {
      throw redirect({
        to: "/auth/login",
        search: { redirect: location.href },
      });
    }
  },
});

const dashboardRoute = createRoute({
  getParentRoute: () => authLayoutRoute,
  path: "/dashboard",
  component: DashboardPage,
});

const incidentsRoute = createRoute({
  getParentRoute: () => authLayoutRoute,
  path: "/incidents",
  component: IncidentsListPage,
});

const incidentDetailRoute = createRoute({
  getParentRoute: () => authLayoutRoute,
  path: "/incidents/$incidentId",
  component: IncidentDetailPage,
});

const panicSessionsRoute = createRoute({
  getParentRoute: () => authLayoutRoute,
  path: "/panic",
  component: PanicSessionsListPage,
});

const panicSessionDetailRoute = createRoute({
  getParentRoute: () => authLayoutRoute,
  path: "/panic/$sessionId",
  component: PanicSessionDetailPage,
});

const predictionsRoute = createRoute({
  getParentRoute: () => authLayoutRoute,
  path: "/predictions",
  component: PredictionsPage,
});

const statisticsRoute = createRoute({
  getParentRoute: () => authLayoutRoute,
  path: "/statistics",
  component: StatisticsPage,
});

const exportRoute = createRoute({
  getParentRoute: () => authLayoutRoute,
  path: "/export",
  component: ExportPage,
});

const adminUsersRoute = createRoute({
  getParentRoute: () => authLayoutRoute,
  path: "/admin/users",
  component: AdminUsersPage,
  beforeLoad: () => {
    const user = useAuthStore.getState().user;
    if (user?.role !== "ADMIN") {
      throw redirect({ to: "/dashboard" });
    }
  },
});

const routeTree = rootRoute.addChildren([
  loginRoute,
  authLayoutRoute.addChildren([
    dashboardRoute,
    incidentsRoute,
    incidentDetailRoute,
    panicSessionsRoute,
    panicSessionDetailRoute,
    predictionsRoute,
    statisticsRoute,
    exportRoute,
    adminUsersRoute,
  ]),
]);

const router = createRouter({
  routeTree,
  defaultPreload: "intent",
});

declare module "@tanstack/react-router" {
  interface Register {
    router: typeof router;
  }
}

// Estado tipado para la navegación programática de la sección Pánico:
// PanicSessionsListPage pasa la sesión completa via `state` al navegar a
// `/panic/$sessionId`, evitando un refetch inmediato en el detalle.
declare module "@tanstack/history" {
  interface HistoryState {
    session?: PanicSessionSummaryDTO;
  }
}

const App = () => {
  const bootstrap = useAuthStore((s) => s.bootstrap);

  useEffect(() => {
    const unsub = bootstrap();
    return unsub;
  }, [bootstrap]);

  return <RouterProvider router={router} />;
};

export default App;
