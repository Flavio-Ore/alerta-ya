import 'package:flutter/material.dart';

import 'package:alertaya/core/constants/app_colors.dart';

/// Card Urban Sentinel: fondo `surfaceContainerHigh`, sin border 1px,
/// radius 16. Separación con shifts de fondo, no con líneas.
///
/// Si necesita float (elevación visible), pasar [floating] = true
/// para usar una sombra ambient tintada (no gris pura).
class AlertaYaCard extends StatelessWidget {
  const AlertaYaCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.floating = false,
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final bool floating;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color ?? AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
          boxShadow: floating
              ? [
                  BoxShadow(
                    color: AppColors.onSurface.withValues(alpha: 0.08),
                    blurRadius: 32,
                    offset: const Offset(0, 12),
                  ),
                ]
              : null,
        ),
        child: child,
      ),
    );
  }
}
