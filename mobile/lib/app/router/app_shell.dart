import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:alertaya/core/widgets/alertaya_bottom_nav.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  DateTime? _lastBackPress;

  // Mapeo shell index → bottom nav index (el 2 es pánico, no es branch)
  // Shell: 0=Mapa  1=Alertas  2=Riesgo  3=Perfil
  // Nav:   0=Mapa  1=Alertas  2=Pánico  3=Riesgo  4=Perfil
  int _toNavIndex(int shellIndex) => switch (shellIndex) {
        0 => 0,
        1 => 1,
        2 => 3,
        3 => 4,
        _ => 0,
      };

  void _onNavTap(BuildContext context, int navIndex) {
    switch (navIndex) {
      case 0:
        widget.navigationShell.goBranch(0);
      case 1:
        widget.navigationShell.goBranch(1);
      case 2:
        // Pánico no es branch — navega como ruta normal
        context.push('/panic');
      case 3:
        widget.navigationShell.goBranch(2);
      case 4:
        widget.navigationShell.goBranch(3);
    }
  }

  Future<bool> _onBackPressed() async {
    // Si hay una sub-ruta activa dentro del branch (ej: /map/routes),
    // go_router la maneja antes de llegar acá — este callback solo se
    // dispara cuando estamos en la raíz de un branch.

    // Si no estamos en Mapa, volvemos a él.
    if (widget.navigationShell.currentIndex != 0) {
      widget.navigationShell.goBranch(0, initialLocation: true);
      return true; // consumido
    }

    // Estamos en Mapa (root) — doble toque para salir.
    final now = DateTime.now();
    final lastPress = _lastBackPress;
    if (lastPress == null ||
        now.difference(lastPress) > const Duration(seconds: 2)) {
      _lastBackPress = now;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Presioná atrás otra vez para salir'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return true; // consumido — no salir todavía
    }

    // Segundo toque dentro del plazo — dejar que el sistema salga.
    return false;
  }

  @override
  Widget build(BuildContext context) {
    // BackButtonListener de go_router: se integra correctamente con
    // StatefulShellRoute y evita el bypass de PopScope en go_router 13+.
    return BackButtonListener(
      onBackButtonPressed: _onBackPressed,
      child: Scaffold(
        body: widget.navigationShell,
        bottomNavigationBar: AlertaYaBottomNav(
          currentIndex: _toNavIndex(widget.navigationShell.currentIndex),
          onTap: (index) => _onNavTap(context, index),
          onPanicPressed: () => context.push('/panic'),
        ),
      ),
    );
  }
}
