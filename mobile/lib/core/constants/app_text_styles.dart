import 'package:flutter/material.dart';

import 'package:alertaya/core/constants/app_colors.dart';

/// Escala tipográfica Urban Sentinel.
/// Usa DM Sans para todo (display + body). DMSans soporta weights
/// 400 (Regular), 500 (Medium) y 800 (ExtraBold) nativamente. Pesos 600/700
/// los sintetiza Flutter desde Medium.
class AppTextStyles {
  AppTextStyles._();

  static const String _display = 'DMSans';
  static const String _body    = 'DMSans';

  // ─── Display ─────────────────────────────────────────
  static const TextStyle displayLg = TextStyle(
    fontFamily: _display,
    fontWeight: FontWeight.w700,
    fontSize: 56,
    height: 1.1,
    letterSpacing: -1.0,
    color: AppColors.onSurface,
  );

  // ─── Headlines ───────────────────────────────────────
  static const TextStyle headlineLg = TextStyle(
    fontFamily: _display,
    fontWeight: FontWeight.w700,
    fontSize: 32,
    height: 1.2,
    color: AppColors.onSurface,
  );

  static const TextStyle headlineMd = TextStyle(
    fontFamily: _display,
    fontWeight: FontWeight.w700,
    fontSize: 24,
    height: 1.25,
    color: AppColors.onSurface,
  );

  static const TextStyle headlineSm = TextStyle(
    fontFamily: _display,
    fontWeight: FontWeight.w600,
    fontSize: 20,
    height: 1.3,
    color: AppColors.onSurface,
  );

  // ─── Titles ──────────────────────────────────────────
  static const TextStyle titleLg = TextStyle(
    fontFamily: _display,
    fontWeight: FontWeight.w600,
    fontSize: 18,
    height: 1.35,
    color: AppColors.onSurface,
  );

  static const TextStyle titleMd = TextStyle(
    fontFamily: _display,
    fontWeight: FontWeight.w600,
    fontSize: 16,
    height: 1.4,
    color: AppColors.onSurface,
  );

  static const TextStyle titleSm = TextStyle(
    fontFamily: _display,
    fontWeight: FontWeight.w500,
    fontSize: 14,
    height: 1.4,
    color: AppColors.onSurface,
  );

  // ─── Body ────────────────────────────────────────────
  static const TextStyle bodyLg = TextStyle(
    fontFamily: _body,
    fontWeight: FontWeight.w400,
    fontSize: 16,
    height: 1.5,
    color: AppColors.onSurface,
  );

  static const TextStyle bodyMd = TextStyle(
    fontFamily: _body,
    fontWeight: FontWeight.w400,
    fontSize: 14,
    height: 1.5,
    color: AppColors.onSurfaceVariant,
  );

  static const TextStyle bodySm = TextStyle(
    fontFamily: _body,
    fontWeight: FontWeight.w400,
    fontSize: 12,
    height: 1.45,
    color: AppColors.onSurfaceVariant,
  );

  // ─── Labels ──────────────────────────────────────────
  static const TextStyle labelLg = TextStyle(
    fontFamily: _body,
    fontWeight: FontWeight.w600,
    fontSize: 14,
    height: 1.4,
    letterSpacing: 0.1,
    color: AppColors.onSurface,
  );

  static const TextStyle labelMd = TextStyle(
    fontFamily: _body,
    fontWeight: FontWeight.w500,
    fontSize: 12,
    height: 1.35,
    letterSpacing: 0.5,
    color: AppColors.onSurfaceVariant,
  );

  static const TextStyle labelSm = TextStyle(
    fontFamily: _body,
    fontWeight: FontWeight.w500,
    fontSize: 10,
    height: 1.4,
    letterSpacing: 0.5,
    color: AppColors.onSurfaceVariant,
  );

  // ─── Logo lockup ─────────────────────────────────────
  static const TextStyle logoAlerta = TextStyle(
    fontFamily: _display,
    fontWeight: FontWeight.w500,
    fontSize: 24,
    color: AppColors.onSurface,
    letterSpacing: -0.03,
  );

  static const TextStyle logoYa = TextStyle(
    fontFamily: _display,
    fontWeight: FontWeight.w800,
    fontSize: 24,
    color: AppColors.secondary,
    letterSpacing: -0.03,
  );

  // ──────────────────────────────────────────────────────
  // Aliases backward-compat (DEPRECATED).
  // ──────────────────────────────────────────────────────

  @Deprecated('Usar headlineLg.')
  static const TextStyle h1 = headlineLg;

  @Deprecated('Usar headlineMd.')
  static const TextStyle h2 = headlineMd;

  @Deprecated('Usar titleLg.')
  static const TextStyle h3 = titleLg;

  @Deprecated('Usar bodyLg.')
  static const TextStyle body = bodyLg;

  @Deprecated('Usar bodyMd.')
  static const TextStyle bodySecondary = bodyMd;

  @Deprecated('Usar bodyMd.')
  static const TextStyle bodySmall = bodyMd;

  @Deprecated('Usar labelMd.')
  static const TextStyle caption = labelMd;

  @Deprecated('Usar labelSm.')
  static const TextStyle captionSmall = labelSm;

  @Deprecated('Usar labelMd.')
  static const TextStyle label = labelMd;

  @Deprecated('Usar labelLg.')
  static const TextStyle buttonLabel = labelLg;
}
