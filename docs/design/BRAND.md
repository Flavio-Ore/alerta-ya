# BRAND.md — Tokens de Marca AlertaYa

> Fuente de verdad para todos los valores visuales.
> Nunca hardcodear colores, tamaños o tipografía en componentes.
> Siempre referenciar estas constantes.

---

## EL SÍMBOLO OFICIAL

### Descripción del logo
**Campana de alerta azul** con **ondas de sonido ámbar** que emanan desde arriba.

```
Concepto visual:
  Campana (Alerta Ciudadana) + Ondas concéntricas (Inmediatez/Velocidad)
  = AlertaYa

Componentes:
  1. Campana sólida:   forma geométrica limpia, color #1B3A6B
  2. Ondas ámbar:      2–3 arcos concéntricos sobre la campana, color #F5A623
  3. Sin gradientes, sin sombras, sin más de 2 colores
```

### Variantes del símbolo

| Variante | Fondo | Campana | Ondas |
|----------|-------|---------|-------|
| Clara (principal) | `#FFFFFF` | `#1B3A6B` | `#F5A623` |
| Oscura / Negativa | `#0D1B2A` | `#FFFFFF` | `#FFFFFF` |
| Sobre azul noche | `#1B3A6B` | `#FFFFFF` | `#F5A623` |
| Monocromática clara | `#FFFFFF` | `#0D1B2A` | `#0D1B2A` |
| Monocromática oscura | `#0D1B2A` | `#FFFFFF` | `#FFFFFF` |

### Reglas de uso del símbolo — NUNCA ROMPER
```
❌ Sin gradientes en campana ni en ondas
❌ Sin sombras decorativas sobre el símbolo
❌ Sin agregar más colores — máximo 2 (campana + ondas)
❌ Sin rotar el símbolo
❌ Sin deformar las proporciones
❌ Sin usar el símbolo horizontal solo (ratio debe ser cuadrado o ligeramente vertical)
✅ Reconocible a 24px de tamaño mínimo
✅ Las ondas siempre arriba de la campana (nunca debajo ni a los lados)
```

### Archivos de logo en el proyecto
```
assets/shared/logo/
├── alertaya-isotipo.svg          ← Campana + ondas, fondo transparente
├── alertaya-logo-horizontal.svg  ← Isotipo + "AlertaYa" en texto
├── alertaya-logo-dark.svg        ← Versión para fondos oscuros (campana blanca)
└── alertaya-logo-mono.svg        ← 1 solo color (para stamps, bordados, etc.)

mobile/assets/images/logo/        ← Copias para Flutter (mismo contenido)
web/public/assets/logo/           ← Copias para React (mismo contenido)
web/public/favicon.ico            ← Campana sola, 32×32
```

---

## LOGOTIPO — EL NOMBRE

### Composición
```
[Isotipo]  Alerta Ya
            ↑      ↑
          Medium  ExtraBold
          #0D1B2A  #F5A623
```

### Regla crítica del nombre
```
"Alerta" → DM Sans Medium (500), color #0D1B2A en claro / #FFFFFF en oscuro
"Ya"     → DM Sans ExtraBold (800), color #F5A623 SIEMPRE (ambos modos)
Letter-spacing: -0.03em en ambas palabras
Sin espacio entre "Alerta" y "Ya" — son una sola palabra visual
```

---

## PALETA DE COLORES

### Colores principales

| Token | Hex | Uso |
|-------|-----|-----|
| `colorPrimary` | `#1B3A6B` | Azul Noche — campana, botones, nav activo |
| `colorAccent` | `#F5A623` | Ámbar Alerta — ondas, "Ya" en logo, badges urgentes |
| `colorDark` | `#0D1B2A` | Noche Profunda — texto principal, bottom nav |
| `colorBgLight` | `#FFFFFF` | Fondo claro |
| `colorBgGray` | `#F4F6F9` | Fondo gris — formularios |
| `colorBgDark` | `#1A1D23` | Fondo oscuro — splash, pánico, panel web |
| `colorBgDark2` | `#141720` | Sidebar panel web |

### Colores de severidad

| Token | Hex | Uso |
|-------|-----|-----|
| `colorLow` | `#22C55E` | Severidad LEVE |
| `colorModerate` | `#F5A623` | Severidad MODERADA — igual al acento |
| `colorCritical` | `#EF4444` | Severidad CRÍTICA — pánico |

### Colores de texto

| Token | Hex | Uso |
|-------|-----|-----|
| `colorTextPrimary` | `#0D1B2A` | Texto principal modo claro |
| `colorTextSecondary` | `#6B7A8D` | Subtítulos, placeholders |
| `colorTextMuted` | `#C4CDD8` | Placeholders, separadores |
| `colorTextWhite` | `#FFFFFF` | Texto sobre fondos oscuros |

---

## IMPLEMENTACIÓN POR PLATAFORMA

### Flutter — `lib/core/constants/app_colors.dart`
```dart
class AppColors {
  static const Color primary    = Color(0xFF1B3A6B); // Campana
  static const Color accent     = Color(0xFFF5A623); // Ondas + "Ya"
  static const Color dark       = Color(0xFF0D1B2A);
  static const Color bgLight    = Color(0xFFFFFFFF);
  static const Color bgGray     = Color(0xFFF4F6F9);
  static const Color bgDark     = Color(0xFF1A1D23);
  static const Color bgDark2    = Color(0xFF141720);
  static const Color severityLow      = Color(0xFF22C55E);
  static const Color severityModerate = Color(0xFFF5A623);
  static const Color severityCritical = Color(0xFFEF4444);
  static const Color textPrimary   = Color(0xFF0D1B2A);
  static const Color textSecondary = Color(0xFF6B7A8D);
  static const Color textMuted     = Color(0xFFC4CDD8);
}
```

### Flutter — Usar el logo con flutter_svg
```dart
// Isotipo solo (campana + ondas) — modo claro
SvgPicture.asset(
  'assets/images/logo/alertaya_isotipo.svg',
  width: 48,
  height: 48,
)

// Logo horizontal — modo oscuro (sidebar, splash)
SvgPicture.asset(
  'assets/images/logo/alertaya_logo_dark.svg',
  height: 32,
)

// En el splash screen (grande, centrado)
SvgPicture.asset(
  'assets/images/logo/alertaya_isotipo.svg',
  width: 120,
  height: 120,
)
```

### TypeScript/React — `web/src/core/constants/colors.ts`
```typescript
export const colors = {
  primary:    '#1B3A6B', // Campana
  accent:     '#F5A623', // Ondas + "Ya"
  dark:       '#0D1B2A',
  bgLight:    '#FFFFFF',
  bgGray:     '#F4F6F9',
  bgDark:     '#1A1D23',
  bgDark2:    '#141720',
  severityLow:      '#22C55E',
  severityModerate: '#F5A623',
  severityCritical: '#EF4444',
  textPrimary:   '#0D1B2A',
  textSecondary: '#6B7A8D',
  textMuted:     '#C4CDD8',
} as const;
```

### React — Usar el logo en componentes
```tsx
// Sidebar oscuro del panel autoridades
<img
  src="/assets/logo/alertaya-logo-dark.svg"
  alt="AlertaYa"
  style={{ height: 32 }}
/>

// Navbar claro o login
<img
  src="/assets/logo/alertaya-logo-horizontal.svg"
  alt="AlertaYa"
  style={{ height: 32 }}
/>

// App icon grande (onboarding)
<img
  src="/assets/logo/alertaya-isotipo.svg"
  alt="AlertaYa"
  style={{ width: 80, height: 80 }}
/>
```

### Tailwind — `web/tailwind.config.ts`
```typescript
theme: {
  extend: {
    colors: {
      'ay-primary':    '#1B3A6B',
      'ay-accent':     '#F5A623',
      'ay-dark':       '#0D1B2A',
      'ay-bg-dark':    '#1A1D23',
      'ay-bg-dark2':   '#141720',
      'ay-low':        '#22C55E',
      'ay-moderate':   '#F5A623',
      'ay-critical':   '#EF4444',
      'ay-text-sec':   '#6B7A8D',
    }
  }
}
```

---

## TIPOGRAFÍA

### Familia
- **DM Sans** (Google Fonts) — principal en toda la app
- Fallback: `'Barlow', 'Nunito Sans', Arial, sans-serif`
- Sin serifs en ningún elemento de UI

### Pesos usados
| Peso | Valor | Uso |
|------|-------|-----|
| Medium | 500 | Body, "Alerta" en logotipo, labels |
| SemiBold | 600 | Subtítulos de sección |
| Bold | 700 | Títulos de pantalla, botones |
| ExtraBold | 800 | "Ya" en logotipo, números grandes, CTAs |

### Escala de tamaños
| Rol | Tamaño | Peso |
|-----|--------|------|
| Logo display | 32–72px | 500 + 800 |
| Heading h1 | 24–28px | 700 |
| Heading h2 | 18–22px | 700 |
| Body | 14–16px | 500 |
| Caption | 11–13px | 500 |
| Label / tag | 10–11px | 600 |

---

## BORDES, RADIOS Y ESPACIADO

```
Botones principales:    border-radius: 28px (pill)
Cards / contenedores:   border-radius: 14–16px
Chips / badges:         border-radius: 100px (pill)
Inputs:                 border-radius: 10–12px

Bordes:
  Cards claro:          1px solid #E2E8F0
  Cards oscuro:         0.5px solid #2D3A4A
  Focus en inputs:      2px solid #1B3A6B

Espaciado (sistema 8pt):
  4px · 8px · 12px · 16px · 20px · 24px · 32px · 48px
```

---

## ÍCONOS DE UI (distintos al logo)

- **Flutter**: paquete `iconsax`
- **React Web**: librería `lucide-react`
- Tamaño estándar: 20–24px en UI, 16px en listas densas
- Color: heredar del contexto — nunca hardcodear
- El ícono del botón de pánico en bottom nav: círculo `#EF4444`, 44px, sin label
