import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:alertaya/features/alerts/presentation/pages/alerts_page.dart';
import 'package:alertaya/features/auth/presentation/pages/login_page.dart';
import 'package:alertaya/features/auth/presentation/pages/onboarding_page.dart';
import 'package:alertaya/features/map/presentation/pages/map_page.dart';
import 'package:alertaya/features/panic/presentation/pages/panic_page.dart';
import 'package:alertaya/features/profile/presentation/pages/profile_page.dart';
import 'package:alertaya/features/report/presentation/pages/dynamic_form_page.dart';
import 'package:alertaya/features/report/presentation/pages/incident_type_page.dart';
import 'package:alertaya/features/report/presentation/pages/report_confirmation_page.dart';
import 'package:alertaya/features/risk/presentation/pages/risk_dashboard_page.dart';
import 'app_shell.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    // Onboarding + auth — fuera del shell
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashRedirectPage(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingPage(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),

    // Pánico — fuera del shell: durante S10 el bottom nav no existe
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
                  builder: (context, state) => IncidentDetailSheetPage(
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

// Placeholder pages — se implementan en sus features
class SplashRedirectPage extends StatelessWidget {
  const SplashRedirectPage({super.key});
  @override
  Widget build(BuildContext context) {
    // TODO(router): verificar onboarding completado y redirigir
    return const Scaffold();
  }
}

class IncidentDetailSheetPage extends StatelessWidget {
  const IncidentDetailSheetPage({super.key, required this.incidentId});
  final String incidentId;
  @override
  Widget build(BuildContext context) => const Scaffold();
}

class RouteComparatorPage extends StatelessWidget {
  const RouteComparatorPage({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold();
}
