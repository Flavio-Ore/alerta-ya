import 'package:flutter/material.dart';

import 'package:alertaya/core/constants/app_colors.dart';
import 'package:alertaya/core/constants/app_text_styles.dart';

/// Variantes del botón Urban Sentinel.
///   - [primary]: Azul Noche, CTA estándar.
///   - [amberGlow]: gradiente ámbar para CTAs urgentes (no pánico).
///   - [danger]: fondo `tertiaryContainer` para acciones destructivas / pánico.
enum AlertaYaButtonVariant { primary, amberGlow, danger }

/// Botón primario de AlertaYa.
/// Pill (radius 999), alto 52px, sin sombras grises.
class AlertaYaButton extends StatelessWidget {
  const AlertaYaButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isFullWidth = true,
    this.variant = AlertaYaButtonVariant.primary,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isFullWidth;
  final AlertaYaButtonVariant variant;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null;
    final foreground = _foregroundFor(variant);
    final child = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(foreground),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: foreground),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: AppTextStyles.labelLg.copyWith(color: foreground),
              ),
            ],
          );

    return Opacity(
      opacity: isDisabled ? 0.4 : 1.0,
      child: SizedBox(
        width: isFullWidth ? double.infinity : null,
        height: 52,
        child: Material(
          color: Colors.transparent,
          shape: const StadiumBorder(),
          clipBehavior: Clip.antiAlias,
          child: Ink(
            decoration: _decorationFor(variant),
            child: InkWell(
              onTap: isLoading || isDisabled ? null : onPressed,
              customBorder: const StadiumBorder(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Center(child: child),
              ),
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _decorationFor(AlertaYaButtonVariant v) {
    switch (v) {
      case AlertaYaButtonVariant.primary:
        return const BoxDecoration(
          color: AppColors.primaryContainer,
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.all(Radius.circular(999)),
        );
      case AlertaYaButtonVariant.amberGlow:
        return const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.secondary, AppColors.secondaryContainer],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.all(Radius.circular(999)),
        );
      case AlertaYaButtonVariant.danger:
        return const BoxDecoration(
          color: AppColors.tertiaryContainer,
          borderRadius: BorderRadius.all(Radius.circular(999)),
        );
    }
  }

  Color _foregroundFor(AlertaYaButtonVariant v) {
    switch (v) {
      case AlertaYaButtonVariant.primary:
        return AppColors.onPrimaryContainer;
      case AlertaYaButtonVariant.amberGlow:
        return AppColors.onSecondary;
      case AlertaYaButtonVariant.danger:
        return AppColors.onTertiaryContainer;
    }
  }
}

/// Botón secundario outlined — ghost border (no 1px sólido).
class AlertaYaOutlinedButton extends StatelessWidget {
  const AlertaYaOutlinedButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isFullWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isFullWidth;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onPressed == null ? 0.4 : 1.0,
      child: SizedBox(
        width: isFullWidth ? double.infinity : null,
        height: 52,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: BorderSide(
              color: AppColors.outlineVariant.withValues(alpha: 0.15),
            ),
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(horizontal: 24),
          ),
          onPressed: onPressed,
          child: Text(
            label,
            style: AppTextStyles.labelLg.copyWith(color: AppColors.primary),
          ),
        ),
      ),
    );
  }
}
