import 'package:flutter/material.dart';

import 'package:alertaya/core/constants/app_colors.dart';

/// Card base de AlertaYa.
/// Reglas UI_RULES.md: fondo #FFFFFF, borde 1px #E2E8F0,
/// border-radius 14–16px, sin sombra.
class AlertaYaCard extends StatelessWidget {
  const AlertaYaCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bgLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        child: child,
      ),
    );
  }
}
