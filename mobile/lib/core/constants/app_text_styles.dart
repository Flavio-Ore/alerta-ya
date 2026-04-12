import 'package:flutter/material.dart';

import 'package:alertaya/core/constants/app_colors.dart';

/// Escala tipográfica de AlertaYa — fuente: docs/design/BRAND.md
/// Fuente: DM Sans. Siempre referenciar desde aquí.
class AppTextStyles {
  AppTextStyles._();

  static const String _fontFamily = 'DMSans';

  // Headings
  static const TextStyle h1 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.03,
  );

  static const TextStyle h2 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.03,
  );

  // Body
  static const TextStyle body = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodySecondary = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  // Caption
  static const TextStyle caption = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  // Label / tag
  static const TextStyle label = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.02,
  );

  // Botón
  static const TextStyle buttonLabel = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textWhite,
  );

  // Logo "Alerta" parte
  static const TextStyle logoAlerta = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w500,
    color: AppColors.dark,
    letterSpacing: -0.03,
  );

  // Logo "Ya" parte
  static const TextStyle logoYa = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w800,
    color: AppColors.accent,
    letterSpacing: -0.03,
  );
}
