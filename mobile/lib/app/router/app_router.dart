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

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    // Onboarding — solo primera vez
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

    // Bottom nav principal
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
    GoRoute(
      path: '/alerts',
      builder: (context, state) => const AlertsPage(),
    ),
    GoRoute(
      path: '/panic',
      builder: (context, state) => const PanicPage(),
    ),
    GoRoute(
      path: '/risk',
      builder: (context, state) => const RiskDashboardPage(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfilePage(),
    ),

    // Flujo de reporte — FAB desde /map
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
