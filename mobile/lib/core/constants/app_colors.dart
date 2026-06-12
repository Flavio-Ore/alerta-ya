import 'package:flutter/material.dart';

/// Tokens Urban Sentinel — The Nocturnal Authority (full DARK).
/// Fuente de verdad. NUNCA hardcodear hex en widgets.
///
/// Reglas:
///   - No-Line Rule: separar contenido con shifts de fondo, no con borders 1px.
///   - Ghost border: si necesitás borde, usar `outlineVariant` @15%.
///   - Pure black PROHIBIDO: usar `surface` como negro más oscuro.
///   - Amber Glow: CTAs urgentes usan gradiente `secondary → secondaryContainer`.
class AppColors {
  AppColors._();

  // ─── Surface tiers (Tonal Layering) ──────────────────
  static const Color surface                  = Color(0xFF061423);
  static const Color surfaceContainerLowest   = Color(0xFF020F1E);
  static const Color surfaceContainerLow      = Color(0xFF0F1C2C);
  static const Color surfaceContainer         = Color(0xFF132030);
  static const Color surfaceContainerHigh     = Color(0xFF1E2B3B);
  static const Color surfaceContainerHighest  = Color(0xFF283646);
  static const Color surfaceBright            = Color(0xFF2D3A4A);
  static const Color surfaceDim               = Color(0xFF061423);
  static const Color background               = Color(0xFF061423);

  // ─── Text / On-surface ───────────────────────────────
  static const Color onSurface          = Color(0xFFD6E4F9);
  static const Color onSurfaceVariant   = Color(0xFFC4C6D0);
  static const Color outline            = Color(0xFF8E909A);
  static const Color outlineVariant     = Color(0xFF44474F);

  // ─── Brand: Primary (Azul Noche) ─────────────────────
  static const Color primary             = Color(0xFFACC7FF);
  static const Color primaryContainer    = Color(0xFF1B3A6B);
  static const Color onPrimary           = Color(0xFF0D2F60);
  static const Color onPrimaryContainer  = Color(0xFFDCE7FF);

  // ─── Brand: Secondary (Ámbar Alerta) ─────────────────
  static const Color secondary             = Color(0xFFFFB955);
  static const Color secondaryContainer    = Color(0xFFDC9100);
  static const Color onSecondary           = Color(0xFF452B00);
  static const Color onSecondaryContainer  = Color(0xFF4F3100);

  // ─── Tertiary (Rojo Pánico) ──────────────────────────
  static const Color tertiary             = Color(0xFFFFB3AD);
  static const Color tertiaryContainer    = Color(0xFF7C000F);
  static const Color onTertiary           = Color(0xFF68000A);
  static const Color onTertiaryContainer  = Color(0xFFFF7E77);

  // ─── Error ───────────────────────────────────────────
  static const Color error             = Color(0xFFFFB4AB);
  static const Color errorContainer    = Color(0xFF93000A);
  static const Color onError           = Color(0xFF690005);
  static const Color onErrorContainer  = Color(0xFFFFDAD6);

  // ─── Semánticos extra ────────────────────────────────
  /// Éxito / completado — verde esmeralda para dark theme.
  static const Color success = Color(0xFF34D399);

  // ─── Severidad (semántico) ───────────────────────────
  /// Crítico (panic / severe) — rojo brillante.
  static const Color severityCritical  = Color(0xFFEF4444);

  /// Moderado — ámbar alerta.
  static const Color severityModerate  = Color(0xFFFFB955);

  /// Leve — quiet, usa onSurface tintado.
  static const Color severityLow       = Color(0xFFD6E4F9);

  // ─── Map / Light surfaces ────────────────────────────
  // Superficies claras para componentes que flotan sobre el mapa
  // (search bar, incident sheet). El resto de la app sigue dark.
  static const Color mapSurface              = Color(0xFFFFFFFF);
  static const Color mapSurfaceContainer     = Color(0xFFF1F3F5);
  static const Color mapSurfaceContainerLow  = Color(0xFFF8FAFC);
  static const Color mapOnSurface            = Color(0xFF0D1B2A);
  static const Color mapOnSurfaceVariant     = Color(0xFF4B5563);
  static const Color mapOutline              = Color(0xFFE2E8F0);
  static const Color mapOutlineVariant       = Color(0xFFCBD5E1);

  // ──────────────────────────────────────────────────────
  // Aliases backward-compat (DEPRECATED — migrar progresivamente).
  // ──────────────────────────────────────────────────────

  @Deprecated('Usar primaryContainer. Para Azul Noche brand.')
  static const Color azulNoche = primaryContainer;

  @Deprecated('Usar secondary. Para Ámbar Alerta.')
  static const Color accent = secondary;

  @Deprecated('Usar surface. Diseño es full dark, no hay bgLight.')
  static const Color bgLight = surface;

  @Deprecated('Usar surfaceContainerLow.')
  static const Color bgGray = surfaceContainerLow;

  @Deprecated('Usar surface.')
  static const Color bgDark = surface;

  @Deprecated('Usar surfaceContainerLowest.')
  static const Color bgDark2 = surfaceContainerLowest;

  @Deprecated('Usar surface. Era Noche Profunda, ahora es base dark.')
  static const Color dark = surface;

  @Deprecated('Usar onSurface.')
  static const Color textPrimary = onSurface;

  @Deprecated('Usar onSurfaceVariant.')
  static const Color textSecondary = onSurfaceVariant;

  @Deprecated('Usar outline.')
  static const Color textMuted = outline;

  @Deprecated('Usar onSurface.')
  static const Color textWhite = onSurface;

  // ─── Chips legacy (deprecated, NUEVO mapping: bg@20%, text 100%) ────
  @Deprecated('Usar severityLow.withOpacity(0.20).')
  static final Color chipLowBg = severityLow.withValues(alpha: 0.20);

  @Deprecated('Usar severityLow.')
  static const Color chipLowText = severityLow;

  @Deprecated('Usar severityModerate.withOpacity(0.20).')
  static final Color chipModerateBg = severityModerate.withValues(alpha: 0.20);

  @Deprecated('Usar severityModerate.')
  static const Color chipModerateText = severityModerate;

  @Deprecated('Usar severityCritical.withOpacity(0.20).')
  static final Color chipCriticalBg = severityCritical.withValues(alpha: 0.20);

  @Deprecated('Usar severityCritical.')
  static const Color chipCriticalText = severityCritical;
}
