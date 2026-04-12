/**
 * Tokens de color de AlertaYa — fuente: docs/design/BRAND.md
 * NUNCA hardcodear hex en componentes. Siempre importar desde aquí.
 */
export const colors = {
  primary:    '#1B3A6B', // Azul Noche — campana, botones, nav activo
  accent:     '#F5A623', // Ámbar Alerta — ondas, "Ya" en logo
  dark:       '#0D1B2A', // Noche Profunda
  bgLight:    '#FFFFFF',
  bgGray:     '#F4F6F9',
  bgDark:     '#1A1D23', // Fondo panel web
  bgDark2:    '#141720', // Sidebar

  severityLow:      '#22C55E',
  severityModerate: '#F5A623',
  severityCritical: '#EF4444',

  textPrimary:   '#0D1B2A',
  textSecondary: '#6B7A8D',
  textMuted:     '#C4CDD8',
  textWhite:     '#FFFFFF',

  border:      '#E2E8F0', // Modo claro
  borderDark:  '#2D3A4A', // Modo oscuro
} as const;

export type ColorToken = keyof typeof colors;
