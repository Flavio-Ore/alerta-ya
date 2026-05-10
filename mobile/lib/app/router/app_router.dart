import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:alertaya/app/router/go_router_refresh_stream.dart';
import 'package:alertaya/features/alerts/presentation/pages/alerts_page.dart';
import 'package:alertaya/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:alertaya/features/auth/presentation/pages/login_page.dart';
import 'package:alertaya/features/auth/presentation/pages/onboarding_page.dart';
import 'package:alertaya/features/auth/presentation/pages/splash_page.dart';
import 'package:alertaya/features/incidents/presentation/pages/incident_detail_page.dart';
import 'package:alertaya/features/map/presentation/pages/map_page.dart';
import 'package:alertaya/features/panic/presentation/pages/panic_page.dart';
import 'package:alertaya/features/profile/presentation/pages/profile_page.dart';
import 'package:alertaya/features/report/presentation/pages/dynamic_form_page.dart';
import 'package:alertaya/features/report/presentation/pages/incident_type_page.dart';
import 'package:alertaya/features/report/presentation/pages/report_confirmation_page.dart';
import 'package:alertaya/features/risk/presentation/pages/risk_dashboard_page.dart';
import 'app_shell.dart';

GoRouter createRouter(AuthBloc authBloc, GoRouterRefreshStream refreshStream) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: refreshStream,
    redirect: (context, state) => _authGuard(state, authBloc),
    routes: [
      // Splash — siempre accesible, maneja la lógica de primer lanzamiento
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),

      // Pánico — fuera del shell: pantalla completa sin bottom nav
      GoRoute(
        path: '/panic',
        builder: (context, state) => const PanicPage(),
      ),

      // Flujo de reporte — modal flow iniciado desde el FAB en /map
      GoRoute(
        path: '/report/type',
        builder: (context, state) => const IncidentTypePage(),
      ),
      GoRoute(
        path: '/report/form/:type',
        builder: (context, state) => DynamicFormPage(
          incidentType: state.pathParameters['type']!,
        ),
      ),
      GoRoute(
        path: '/report/confirm',
        builder: (context, state) => const ReportConfirmationPage(),
      ),

      // Shell principal — bottom nav con 4 branches (mapa, alertas, riesgo, perfil)
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(navigationShell: shell),
        branches: [
          // Branch 0: Mapa
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/map',
                builder: (context, state) => const MapPage(),
                routes: [
                  GoRoute(
                    path: 'incident/:id',
                    builder: (context, state) => IncidentDetailPage(
                      incidentId: state.pathParameters['id']!,
                    ),
                  ),
                  GoRoute(
                    path: 'routes',
                    builder: (context, state) => const RouteComparatorPage(),
                  ),
                ],
              ),
            ],
          ),

          // Branch 1: Alertas
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/alerts',
                builder: (context, state) => const AlertsPage(),
              ),
            ],
          ),

          // Branch 2: Riesgo (nav index 3 — el 2 es el pánico central)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/risk',
                builder: (context, state) => const RiskDashboardPage(),
              ),
            ],
          ),

          // Branch 3: Perfil (nav index 4)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfilePage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

String? _authGuard(GoRouterState state, AuthBloc authBloc) {
  final location = state.matchedLocation;
  final authState = authBloc.state;

  const protectedPrefixes = ['/map', '/alerts', '/risk', '/profile', '/panic'];
  final isProtected = protectedPrefixes.any((p) => location.startsWith(p));
  final isAuthPage = location == '/login' || location == '/onboarding';

  if (authState is AuthAuthenticated && isAuthPage) return '/map';
  if (authState is AuthUnauthenticated && isProtected) {
    return authState.isFirstLaunch ? '/onboarding' : '/login';
  }
  if (authState is AuthUnauthenticated &&
      location == '/onboarding' &&
      !authState.isFirstLaunch) {
    return '/login';
  }

  return null;
}

class RouteComparatorPage extends StatelessWidget {
  const RouteComparatorPage({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold();
}
