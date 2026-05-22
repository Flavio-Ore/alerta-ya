import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:alertaya/core/constants/app_colors.dart';
import 'package:alertaya/core/constants/app_constants.dart';
import 'package:alertaya/core/constants/app_text_styles.dart';

/// Bottom navigation Urban Sentinel — glassmorphism + pánico central.
///
/// Reglas:
///   - 5 ítems, pánico en el índice 2 (visual central).
///   - Fondo: `surfaceContainerLow` @80% con blur 40px (glass).
///   - Activo: `secondary` (ámbar). Inactivo: `outline`.
///   - Pánico: círculo elevado `tertiaryContainer` con borde de separación
///     en `surface` para destacarlo del glass.
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
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: Container(
          height: AppConstants.bottomNavHeight + bottomInset,
          color: AppColors.surfaceContainerLow.withValues(alpha: 0.80),
          padding: EdgeInsets.only(bottom: bottomInset),
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
        ),
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
    final color = isActive ? AppColors.secondary : AppColors.outline;
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
            Text(
              label,
              style: AppTextStyles.labelSm.copyWith(color: color),
            ),
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
          color: AppColors.tertiaryContainer,
          shape: BoxShape.circle,
          // Borde de separación visual contra el glass (no es ghost-border,
          // es un anillo del color del fondo para destacar el botón).
          border: Border.all(color: AppColors.surface, width: 3),
          boxShadow: [
            BoxShadow(
              color: AppColors.tertiaryContainer.withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Icon(
          Icons.shield,
          color: AppColors.onTertiaryContainer,
          size: 22,
        ),
      ),
    );
  }
}
