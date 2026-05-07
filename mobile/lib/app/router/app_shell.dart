import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:alertaya/core/widgets/alertaya_bottom_nav.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: AlertaYaBottomNav(
        currentIndex: _toNavIndex(navigationShell.currentIndex),
        onTap: (index) => _onNavTap(context, index),
        onPanicPressed: () => context.go('/panic'),
      ),
    );
  }

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
        navigationShell.goBranch(0);
      case 1:
        navigationShell.goBranch(1);
      case 2:
        // Pánico no es branch — navega como ruta normal
        context.go('/panic');
      case 3:
        navigationShell.goBranch(2);
      case 4:
        navigationShell.goBranch(3);
    }
  }
}
