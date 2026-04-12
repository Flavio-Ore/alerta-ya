import 'package:flutter/material.dart';

/// Tokens de color de AlertaYa — fuente: docs/design/BRAND.md
/// NUNCA hardcodear hex en widgets. Siempre usar esta clase.
class AppColors {
  AppColors._();

  // Colores principales
  static const Color primary    = Color(0xFF1B3A6B); // Azul Noche — campana, botones, nav activo
  static const Color accent     = Color(0xFFF5A623); // Ámbar Alerta — ondas, "Ya" en logo
  static const Color dark       = Color(0xFF0D1B2A); // Noche Profunda — texto, bottom nav

  // Fondos
  static const Color bgLight    = Color(0xFFFFFFFF);
  static const Color bgGray     = Color(0xFFF4F6F9); // Fondos de formularios
  static const Color bgDark     = Color(0xFF1A1D23); // Splash, pánico, panel web
  static const Color bgDark2    = Color(0xFF141720); // Sidebar panel web

  // Severidad
  static const Color severityLow      = Color(0xFF22C55E); // LEVE
  static const Color severityModerate = Color(0xFFF5A623); // MODERADO
  static const Color severityCritical = Color(0xFFEF4444); // CRÍTICO — pánico

  // Texto
  static const Color textPrimary   = Color(0xFF0D1B2A);
  static const Color textSecondary = Color(0xFF6B7A8D);
  static const Color textMuted     = Color(0xFFC4CDD8);
  static const Color textWhite     = Color(0xFFFFFFFF);

  // Chips de severidad — fondos y bordes
  static const Color chipLowBg       = Color(0xFFDCFCE7);
  static const Color chipLowText     = Color(0xFF15803D);
  static const Color chipModerateBg  = Color(0xFFFEF9C3);
  static const Color chipModerateText = Color(0xFF854D0E);
  static const Color chipCriticalBg  = Color(0xFFFEE2E2);
  static const Color chipCriticalText = Color(0xFF991B1B);
}
