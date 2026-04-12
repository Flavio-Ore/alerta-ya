# UI_RULES.md — Reglas UI/UX No Negociables

> Leer antes de crear cualquier widget (Flutter) o componente (React).
> Estas reglas son absolutas — no hay excepciones.

---

## REGLAS ABSOLUTAS (NUNCA ROMPER)

```
1. SIN GRADIENTES — ningún elemento visual tiene gradiente en ningún estado
2. SIN SOMBRAS DECORATIVAS — no box-shadow, no drop-shadow, no elevation decorativa
   (La elevación del botón de pánico es la única excepción técnica en Flutter)
3. SIN MÁS DE 2 COLORES EN EL SÍMBOLO — pin (#1B3A6B) + rayo (#F5A623) únicamente
4. COLORES SIEMPRE DESDE TOKENS — nunca hardcodear hex en widgets/componentes
5. TIPOGRAFÍA: DM Sans siempre — nunca Arial, Roboto, System font directamente
6. BOTTOM NAV MÓVIL: exactamente 5 ítems, pánico en el centro, siempre visible
7. FORMULARIO DINÁMICO: solo opciones múltiples — nunca texto libre
8. IDENTIDAD DEL REPORTANTE: nunca mostrarla en ningún elemento de UI
```

---

## REGLAS DE COMPONENTES

### Botones
```
Primario:
  - Fondo: #1B3A6B | Texto: #FFFFFF | Peso: 700
  - Alto mínimo: 52px | Border-radius: 28px (pill)
  - Estado disabled: opacity 0.4 — no cambiar color
  - Sin sombras

Secundario / Outlined:
  - Fondo: transparent | Borde: 1px solid #1B3A6B | Texto: #1B3A6B
  - Mismos radios y alturas

Destructivo:
  - Solo para acciones críticas (ej: desactivar cuenta)
  - Fondo: transparent | Texto: #EF4444 | Sin borde | Sin fondo coloreado

Acción Waze ("Sigue ahí" / "Ya no está"):
  - "Sigue ahí": fondo #22C55E | texto #FFFFFF | bold
  - "Ya no está": fondo #F4F6F9 | texto #6B7A8D
  - Alto: 52px | Border-radius: 12px (no pill)
  - Ambos ocupan el mismo ancho — side by side

Pánico (círculo central):
  - Fondo: #EF4444 | Ícono: #FFFFFF
  - Diámetro: 44px en bottom nav, 180px en pantalla de pánico
  - Estado activo: borde blanco pulsante — NO gradiente
```

### Chips / Badges de severidad
```
LEVE:     fondo #DCFCE7 | texto #15803D | borde #22C55E44 | dot #22C55E
MODERADO: fondo #FEF9C3 | texto #854D0E | borde #F5A62344 | dot #F5A623
CRÍTICO:  fondo #FEE2E2 | texto #991B1B | borde #EF444444 | dot #EF4444

Forma: pill (border-radius 100px)
Tamaño: 11px bold + dot de 7px a la izquierda
Padding: 3px 10px
```

### Cards
```
Modo claro:
  - Fondo: #FFFFFF
  - Borde: 1px solid #E2E8F0
  - Border-radius: 14–16px
  - Sin sombra

Modo oscuro (panel autoridades):
  - Fondo: #141720
  - Borde: 0.5px solid #2D3A4A
  - Border-radius: 12px
  - Sin sombra
```

### Inputs / Formulario
```
Fondo: #F4F6F9 (claro) | #1C2028 (oscuro)
Borde idle: 1px solid #C4CDD8 | 1px solid #2D3A4A
Borde focus: 2px solid #1B3A6B
Border-radius: 10–12px
Alto: 48–52px
Sin sombra en ningún estado
Placeholder: #C4CDD8
```

### Opciones del formulario dinámico (pill buttons)
```
Estado no seleccionado:
  - Fondo: #FFFFFF | Borde: 1px solid #C4CDD8 | Texto: #6B7A8D

Estado seleccionado:
  - Fondo: #1B3A6B | Borde: 1px solid #1B3A6B | Texto: #FFFFFF

Forma: pill (border-radius: 100px)
Alto: 40px | Padding horizontal: 16px
Sin íconos dentro de las opciones
```

### Pins del mapa
```
Por severidad:
  LEVE:     círculo #22C55E con ícono rayo blanco interior, diámetro 24px
  MODERADO: círculo #F5A623 con ícono rayo blanco interior, diámetro 28px
  CRÍTICO:  círculo #EF4444 con ícono rayo blanco interior, diámetro 32px
            + anillo pulsante exterior del mismo color (solo CRÍTICO)

Sin sombras en los pins
El pin seleccionado (tapeado): escala 1.2x con animación 150ms
```

---

## REGLAS DE LAYOUT

### Móvil
```
Padding horizontal de pantallas: 16–24px (consistente dentro de cada pantalla)
Altura del bottom nav: 64px + safe area
Altura mínima de elementos tocables: 44px (HIG) / 48px (Material)
Máximo 4 toques para llegar a cualquier acción crítica
Textos de UI mínimo: 14px regular, 11px para captions
```

### Web (panel autoridades)
```
Sidebar: 240px fijo — nunca colapsable en MVP
Top bar: 60px fijo
Contenido principal: padding 24–32px
Grid de stats: 4 columnas, gap 12px
Tablas: font-size 13px, row height 52px mínimo
```

---

## REGLAS DE ESTADOS

### Loading
```
Usar shimmer/skeleton en lugar de spinners para listas y cards grandes
Usar spinner lineal delgado (#1B3A6B) para acciones puntuales (login, envío)
Nunca bloquear la pantalla completa con un loader opaco en acciones secundarias
```

### Error
```
Toast / snackbar en la parte inferior — nunca modales para errores menores
Color: #EF4444 — texto descriptivo del error, no códigos técnicos
El toast desaparece en 4 segundos automáticamente
```

### Empty state
```
Ícono relevante (SVG) + título + descripción corta
Sin ilustraciones complejas
Botón de acción si aplica ("Reportar el primero")
```

### Modo pánico activo
```
Pantalla completa — sin bottom nav visible
Fondo: #1A0505 (rojo muy oscuro)
Banner rojo superior: "MODO PÁNICO ACTIVO"
El usuario NO puede navegar a otras secciones durante el pánico
Solo visible: estado de grabación + deactivation PIN input
```

---

## REGLAS DE ANIMACIÓN

```
Duración estándar: 150–200ms
Duración de transición de página: 300ms
Easing: ease-out para entradas, ease-in para salidas

Permitido:
  - Shimmer de loading (loop continuo, sutil)
  - Scale 1.0→1.2 en pin seleccionado
  - Fade in/out para toasts
  - Slide up del bottom sheet
  - Anillo pulsante en pin CRÍTICO

NO permitido:
  - Animaciones de más de 500ms
  - Animaciones en bucle en elementos de datos (confunde al usuario)
  - Parallax
  - Animaciones de partículas
  - Cualquier efecto que desvíe la atención del contenido de seguridad
```

---

## ACCESIBILIDAD

```
Contraste mínimo: 4.5:1 para texto normal, 3:1 para texto grande
Tamaño mínimo de área tocable: 44×44px
Labels de accesibilidad en todos los íconos sin texto
Soporte de modo oscuro del sistema (pero los colores de severidad no cambian)
No depender solo del color para comunicar severidad — usar también texto y forma
```
