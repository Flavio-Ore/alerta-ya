import 'package:flutter/material.dart';

import 'package:alertaya/core/constants/app_colors.dart';
import 'package:alertaya/core/constants/app_text_styles.dart';

/// Botón primario de AlertaYa.
/// Reglas UI_RULES.md: fondo #1B3A6B, texto #FFFFFF, alto mínimo 52px,
/// border-radius 28px (pill), sin sombras, disabled = opacity 0.4.
class AlertaYaButton extends StatelessWidget {
  const AlertaYaButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isFullWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isFullWidth;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onPressed == null ? 0.4 : 1.0,
      child: SizedBox(
        width: isFullWidth ? double.infinity : null,
        height: 52,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.bgLight,
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(horizontal: 24),
          ),
          onPressed: isLoading ? null : onPressed,
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.bgLight),
                  ),
                )
              : Text(label, style: AppTextStyles.buttonLabel),
        ),
      ),
    );
  }
}

/// Botón secundario outlined.
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
            side: const BorderSide(color: AppColors.primary),
            shape: const StadiumBorder(),
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24),
          ),
          onPressed: onPressed,
          child: Text(
            label,
            style: AppTextStyles.buttonLabel.copyWith(color: AppColors.primary),
          ),
        ),
      ),
    );
  }
}
