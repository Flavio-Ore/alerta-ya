import 'package:flutter/material.dart';

import 'package:alertaya/core/constants/app_colors.dart';
import 'package:alertaya/core/constants/app_constants.dart';
import 'package:alertaya/core/constants/app_text_styles.dart';

/// Bottom navigation con pánico central.
/// Reglas: exactamente 5 ítems, pánico en el centro (#EF4444, 44px, elevado)
/// Estado activo: #F5A623. Estado inactivo: #6B7A8D. Fondo: #0D1B2A
class AlertaYaBottomNav extends StatelessWidget {
  const AlertaYaBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onPanicPressed,
  });

  final int currentIndex;

  /// 0=Mapa, 1=Alertas, 2=Pánico, 3=Riesgo, 4=Perfil
  final ValueChanged<int> onTap;
  final VoidCallback onPanicPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppConstants.bottomNavHeight + MediaQuery.of(context).padding.bottom,
      color: AppColors.dark,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            icon: Icons.map_outlined,
            label: 'Mapa',
            isActive: currentIndex == 0,
            onTap: () => onTap(0),
          ),
          _NavItem(
            icon: Icons.notifications_outlined,
            label: 'Alertas',
            isActive: currentIndex == 1,
            onTap: () => onTap(1),
          ),
          // Botón de pánico central
          _PanicButton(onPressed: onPanicPressed),
          _NavItem(
            icon: Icons.shield_outlined,
            label: 'Riesgo',
            isActive: currentIndex == 3,
            onTap: () => onTap(3),
          ),
          _NavItem(
            icon: Icons.person_outline,
            label: 'Perfil',
            isActive: currentIndex == 4,
            onTap: () => onTap(4),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.accent : AppColors.textSecondary;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 3),
            Text(label, style: AppTextStyles.label.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}

class _PanicButton extends StatelessWidget {
  const _PanicButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: AppConstants.panicButtonDiameter,
        height: AppConstants.panicButtonDiameter,
        decoration: BoxDecoration(
          color: AppColors.severityCritical,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: const Icon(
          Icons.shield,
          color: Colors.white,
          size: 22,
        ),
      ),
    );
  }
}
