import { FC } from 'react';
import {
  createRouter,
  createRoute,
  createRootRoute,
  RouterProvider,
  redirect,
  Outlet,
} from '@tanstack/react-router';

import { Sidebar } from './core/components/layout/Sidebar';
import { TopBar } from './core/components/layout/TopBar';
import LoginPage from './features/auth/pages/LoginPage';
import DashboardPage from './features/dashboard/pages/DashboardPage';
import IncidentsListPage from './features/incidents/pages/IncidentsListPage';
import IncidentDetailPage from './features/incidents/pages/IncidentDetailPage';
import PredictionsPage from './features/predictions/pages/PredictionsPage';
import StatisticsPage from './features/statistics/pages/StatisticsPage';
import ExportPage from './features/export/pages/ExportPage';

// TODO(auth): replace with real auth store check
const isAuthenticated = () => true;
const hasAuthorityRole = () => true;

// Layout con Sidebar + TopBar para rutas protegidas
function AuthLayout() {
  return (
    <div className="flex h-screen bg-ay-bg-dark overflow-hidden">
      <Sidebar />
      <div className="flex flex-col flex-1 overflow-hidden">
        <TopBar />
        <main className="flex-1 overflow-auto p-6">
          <Outlet />
        </main>
      </div>
    </div>
  );
}

// Root
const rootRoute = createRootRoute();

// Ruta pública — login
const loginRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: '/auth/login',
  component: LoginPage,
});

// Layout protegido — verifica auth + rol AUTHORITY
const authLayoutRoute = createRoute({
  getParentRoute: () => rootRoute,
  id: 'auth',
  component: AuthLayout,
  beforeLoad: ({ location }) => {
    if (!isAuthenticated() || !hasAuthorityRole()) {
      throw redirect({
        to: '/auth/login',
        search: { redirect: location.href },
      });
    }
  },
});

const dashboardRoute = createRoute({
  getParentRoute: () => authLayoutRoute,
  path: '/dashboard',
  component: DashboardPage,
});

const incidentsRoute = createRoute({
  getParentRoute: () => authLayoutRoute,
  path: '/incidents',
  component: IncidentsListPage,
});

const incidentDetailRoute = createRoute({
  getParentRoute: () => authLayoutRoute,
  path: '/incidents/$incidentId',
  component: IncidentDetailPage,
});

const predictionsRoute = createRoute({
  getParentRoute: () => authLayoutRoute,
  path: '/predictions',
  component: PredictionsPage,
});

const statisticsRoute = createRoute({
  getParentRoute: () => authLayoutRoute,
  path: '/statistics',
  component: StatisticsPage,
});

const exportRoute = createRoute({
  getParentRoute: () => authLayoutRoute,
  path: '/export',
  component: ExportPage,
});

const routeTree = rootRoute.addChildren([
  loginRoute,
  authLayoutRoute.addChildren([
    dashboardRoute,
    incidentsRoute,
    incidentDetailRoute,
    predictionsRoute,
    statisticsRoute,
    exportRoute,
  ]),
]);

const router = createRouter({
  routeTree,
  defaultPreload: 'intent',
});

declare module '@tanstack/react-router' {
  interface Register {
    router: typeof router;
  }
}

const App: FC = () => <RouterProvider router={router} />;

export default App;
