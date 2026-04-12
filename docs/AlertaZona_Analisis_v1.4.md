# 📋 ANÁLISIS DE PROYECTO — AlertaZona
**Red Ciudadana de Seguridad en Tiempo Real con Inteligencia Artificial**
> Documento de análisis — Versión 1.4 — 6 de abril de 2026

---

## TABLA DE CONTENIDOS
1. [Procesos de Negocio](#1-procesos-de-negocio)
2. [Restricciones de Negocio](#2-restricciones-de-negocio)
3. [Casos de Uso](#3-casos-de-uso)
4. [Requerimientos](#4-requerimientos)
5. [Stack Tecnológico](#5-stack-tecnológico)
6. [Módulo de Inteligencia Artificial](#6-módulo-de-inteligencia-artificial)
7. [Anexo — Librerías y Recursos](#7-anexo--librerías-y-recursos)

---

## 1. PROCESOS DE NEGOCIO

### 1.1 Reporte de Incidente (Ciudadano)
1. El ciudadano detecta un incidente de seguridad en su entorno.
2. Abre la app AlertaZona y selecciona el **tipo de incidente** (robo, acoso, accidente, extorsión, persona sospechosa).
3. El sistema captura automáticamente la geolocalización (GPS).
4. El sistema presenta un **formulario dinámico estructurado** con 3–4 preguntas de opción múltiple adaptadas al tipo de incidente seleccionado (ver sección 1.6).
5. El ciudadano adjunta evidencia opcional (foto, audio o video).
6. El reporte se envía al backend (completable en ≤10 segundos incluyendo el formulario).
7. El sistema aplica **rate limiting**: máximo 3 reportes por hora por cuenta.
8. El módulo de IA verifica coherencia del reporte en <5 segundos, usando también las respuestas del formulario dinámico para detectar incoherencias internas.
9. El sistema aplica el **threshold de publicación**:
   - 1 reporte solo → se guarda internamente, **NO se publica ni notifica**
   - 2 reportes independientes en 15 min → se publica como LEVE, sin push
   - 3+ reportes en 15 min → MODERADO + notificación push a usuarios cercanos
   - 5+ reportes en 20 min → CRÍTICO + push + alerta a comisaría
10. Si múltiples usuarios responden la misma opción crítica en el formulario (ej: todos marcan "arma de fuego"), el sistema **sube automáticamente la severidad** sin esperar la IA.
11. Si hay **50+ reportes en el mismo punto en 5 minutos**, el sistema agrupa todo en un único evento con contador.
12. El reporte **expira automáticamente en 30 minutos** si no recibe confirmación de otros usuarios.
13. La identidad del reportante es **anónima para el público**, registrada cifrada internamente (solo con orden judicial).

### 1.2 Alerta Proactiva por Geofencing (Ciudadano Pasivo)
1. La app monitorea la ubicación GPS del usuario en segundo plano.
2. El sistema cruza la ubicación con el índice de riesgo de zonas activas usando **PostGIS** (`ST_DWithin()`).
3. Si el usuario entra a una zona de riesgo alto (radio configurable, default 500m), se dispara notificación push automática.
4. **Cooldown de notificaciones:** máximo 1 push cada 3 minutos del mismo tipo/zona por usuario.
5. El usuario recibe la alerta y puede decidir cambiar su ruta.

### 1.3 Activación de Botón de Pánico

#### Método de activación
| Método | Cómo se activa |
|---|---|
| **Desde la app** | Mantener presionado el botón de pánico por 3 segundos |
| **Sin abrir la app** | Presionar el botón físico de volumen 3 veces seguidas |
| **Por voz** | Pronunciar la palabra clave configurada por el usuario (ajustes de la app) |

#### Flujo tras la activación
1. El sistema inicia **grabación de audio/video en segundo plano** (continua, oculta al agresor).
2. Simultáneamente **comienza a sonar una alarma fuerte** desde el altavoz del dispositivo.
3. La alarma **no puede silenciarse con los botones físicos de volumen** durante el modo pánico activo.
4. La ubicación GPS en vivo se comparte con el contacto de confianza del usuario.
5. Se envía alerta inmediata al serenazgo más cercano con coordenadas en tiempo real.

#### Desactivación
Mediante **PIN de 4 dígitos** desde la **notificación persistente** en la barra de estado (sin abrir la app).

| Escenario | Comportamiento del sistema |
|---|---|
| **Desactivación normal** | PIN correcto → alarma se detiene, grabación se guarda cifrada en servidor |
| **App cerrada forzosamente** | Foreground Service mantiene alarma y grabación; solo se detiene con PIN |
| **PIN incorrecto 3 veces** | Alarma se mantiene activa + notificación adicional al contacto de confianza |
| **Sin batería** | Fragmentos grabados se sincronizan al reiniciar con conexión |
| **Sin conexión** | Grabación continúa local; se sincroniza al recuperar señal |
| **Tiempo máximo** | 60 minutos, segmentado en bloques de 10 min |

### 1.4 Gestión de Incidentes (Autoridad)
1. El supervisor accede al panel web con 2FA.
2. Visualiza el mapa de calor en tiempo real. **Nunca ve la identidad del reportante.**
3. Puede ver las respuestas del formulario dinámico del reporte (tipo de arma, número de agresores, etc.) para evaluar la gravedad.
4. Asigna una unidad operativa al incidente con un clic.
5. El ciudadano recibe actualización de estado (recibido → en atención → cerrado).
6. El sistema registra la acción para trazabilidad y reportes estadísticos.

### 1.5 Predicción y Análisis de Riesgo (IA)
1. La IA recopila datos históricos de reportes **incluyendo las respuestas del formulario dinámico** como features adicionales.
2. Genera predicciones probabilísticas de riesgo por zona, hora y día de semana.
3. El modelo se reentrena automáticamente cada 30 días con nuevos datos.
4. Los resultados se exponen en el dashboard del ciudadano y en el panel de autoridades.

### 1.6 Formulario Dinámico por Tipo de Incidente (Structured Reporting)

> El formulario se adapta automáticamente al tipo de incidente seleccionado. Máximo 4 preguntas de opción múltiple. Siempre incluye "No sé" como opción para no bloquear el reporte en situación de estrés.

#### Tipo: Robo / Asalto
| # | Pregunta | Opciones |
|---|---|---|
| 1 | ¿Cuántas personas involucradas? | 1 persona / 2–3 personas / Grupo grande / No sé |
| 2 | ¿El agresor tenía arma? | Sí, arma de fuego / Sí, arma blanca / No / No vi |
| 3 | ¿Sigue en la zona? | Sí, todavía está / Huyó a pie / Huyó en vehículo / No sé |
| 4 | ¿Dirección de huida? | Norte / Sur / Este / Oeste / No sé |

#### Tipo: Accidente de Tránsito
| # | Pregunta | Opciones |
|---|---|---|
| 1 | ¿Hay personas heridas? | Sí, heridos visibles / No parece / No sé |
| 2 | ¿Cuántos vehículos? | 1 / 2 / Más de 2 |
| 3 | ¿Bloquea el tráfico? | Sí, completamente / Parcialmente / No |
| 4 | ¿Hay atención médica presente? | Sí / No / En camino |

#### Tipo: Persona Sospechosa
| # | Pregunta | Opciones |
|---|---|---|
| 1 | ¿Qué comportamiento observas? | Merodea vehículos / Sigue a personas / Actitud agresiva / Otro |
| 2 | ¿Sigue en la zona? | Sí / No / No sé |
| 3 | ¿Va a pie o en vehículo? | A pie / En vehículo / No sé |

#### Tipo: Acoso
| # | Pregunta | Opciones |
|---|---|---|
| 1 | ¿Tipo de acoso? | Verbal / Físico / Seguimiento / Otro |
| 2 | ¿El agresor sigue en la zona? | Sí / No / No sé |
| 3 | ¿Hay más personas afectadas? | Solo una persona / Varias personas / No sé |

#### Tipo: Extorsión
| # | Pregunta | Opciones |
|---|---|---|
| 1 | ¿Modalidad? | Llamada telefónica / Presencial / Mensaje de texto / Otro |
| 2 | ¿Hay amenaza directa? | Sí, amenaza física / Sí, amenaza a familiar / Solo económica / No sé |
| 3 | ¿Es reincidente en la zona? | Primera vez / Ya ha ocurrido antes / No sé |

#### Regla de escalada automática por formulario
Si 3 o más usuarios distintos responden la misma opción de alta gravedad en el mismo incidente, el sistema escala la severidad automáticamente sin esperar la IA:
- 3+ usuarios marcan **"arma de fuego"** → escala a CRÍTICO
- 3+ usuarios marcan **"heridos visibles"** → escala a CRÍTICO + alerta a comisaría inmediata
- 3+ usuarios marcan **"sigue en la zona"** → extiende la vida del reporte 30 minutos adicionales

---

## 2. RESTRICCIONES DE NEGOCIO

### 2.1 Restricciones de Alcance (MVP)
- 🔴 El MVP está limitado exclusivamente a **Lima Metropolitana** como zona piloto.
- 🔴 No se gestionará el despacho operativo de patrullas PNP/serenazgo.
- 🔴 No se integrarán cámaras de videovigilancia municipales.
- 🔴 No incluye módulo de denuncia formal ante MININTER.
- 🔴 No incluye integración bancaria para denuncias de fraude electrónico.
- 🔴 No se desarrollará versión web para ciudadanos en MVP (solo app móvil + panel autoridades).
- 🟡 En MVP el formulario dinámico cubrirá solo los tipos: **Robo** y **Accidente** (los más frecuentes). Los demás tipos se añaden en iteraciones posteriores.

### 2.2 Restricciones de Anonimato y Privacidad
- **Anonimato público obligatorio:** La identidad del reportante es completamente invisible para todos los demás usuarios, para el panel de autoridades y para el mapa público.
- **Justificación:** Las mafias y organizaciones criminales podrían estar activas en la plataforma; exponer la identidad representa un riesgo físico real.
- **Trazabilidad interna cifrada:** El sistema almacena internamente la identidad cifrada con AES-256, accesible solo con orden judicial (necesario para el sistema de reputación y la ley peruana).
- El sistema debe cumplir la **Ley N° 29733 de Protección de Datos Personales del Perú**.
- Las grabaciones del botón de pánico se almacenan **cifradas con AES-256**; accesibles solo por el usuario autenticado o por autoridades con orden judicial.
- Las **respuestas del formulario dinámico** son visibles en el panel de autoridades pero nunca vinculadas a la identidad del reportante.

### 2.3 Restricciones Legales
- Los reportes solo referencian **coordenadas GPS y tipo de delito**; nunca nombres de personas ni establecimientos comerciales (mitiga riesgo de difamación, Artículo 132 CP).
- Los **términos y condiciones** declaran que el usuario reportante es responsable legal de la veracidad de su reporte.
- El threshold de publicación (mínimo 2 reportes independientes) reduce el riesgo de pánico colectivo (Artículo 315 CP — perturbación de la tranquilidad pública).
- Cumplimiento del **Artículo 8 de la Ley N° 29733** para datos personales sensibles.
- El formulario dinámico **nunca solicita datos personales** del agresor (nombre, documento, descripción facial detallada), solo datos de comportamiento y contexto.

### 2.4 Restricciones de Control de Calidad (Thresholds)
- **Threshold mínimo de publicación:** 2 reportes independientes en 15 minutos para publicar en el mapa.
- **Rate limiting:** Máximo 3 reportes por hora por cuenta.
- **Cooldown de notificaciones push:** 1 push máximo por tipo/zona cada 3 minutos por usuario.
- **Expiración:** Reportes sin confirmación desaparecen del mapa en 30 minutos.
- **Agrupación masiva:** 50+ reportes del mismo punto en 5 min se consolidan en un evento único con contador.
- **Escalada por formulario:** 3+ usuarios con misma respuesta crítica escala severidad automáticamente.
- **Peso de reporte completo vs. incompleto:** Un reporte con formulario completo tiene mayor peso en el threshold que uno sin respuestas.

### 2.5 Restricciones Técnicas
- Las notificaciones push deben entregarse en **menos de 3 segundos** tras la confirmación.
- La app móvil debe operar con **menos de 2 MB de datos por hora** en modo activo.
- La IA de verificación debe responder en **menos de 5 segundos** por reporte.
- El sistema debe soportar al menos **10,000 usuarios concurrentes** en fase piloto.
- Disponibilidad mínima: **99.5% mensual**.
- El servicio de pánico debe operar como **Android Foreground Service** con notificación persistente.

### 2.6 Restricciones del Formulario Dinámico
- Máximo **4 preguntas** por tipo de incidente para no superar los 10 segundos totales del reporte.
- Todas las preguntas deben ser de **opción múltiple** (nunca texto libre) para facilitar el procesamiento automático por la IA.
- Siempre debe existir la opción **"No sé"** en preguntas situacionales para no bloquear el reporte bajo estrés.
- Las respuestas del formulario se almacenan como **JSON estructurado** en la base de datos.

### 2.7 Restricciones de Modelo de IA
- El modelo de IA requerirá un mínimo de **3 meses de datos** para alcanzar precisión del 75–85%.
- El reentrenamiento ocurre cada 30 días sin interrumpir el servicio en producción.
- Las respuestas del formulario dinámico se incorporan como **features adicionales** al modelo desde la primera fase de entrenamiento.

---

## 3. CASOS DE USO

### CU-01: Registrar e Iniciar Sesión
- **Actor:** Ciudadano
- **Descripción:** Registro o login con correo, Google o WhatsApp.
- **Resultado:** Sesión activa JWT. Identidad cifrada internamente; anónima para el público.

### CU-02: Reportar Incidente con Formulario Dinámico
- **Actor:** Ciudadano
- **Descripción:** El usuario selecciona el tipo de incidente, responde el formulario dinámico estructurado (3–4 preguntas de opción múltiple adaptadas al tipo), adjunta evidencia opcional y envía el reporte en ≤10 segundos.
- **Flujo principal:**
  1. Usuario selecciona tipo → aparecen preguntas específicas del tipo
  2. Responde opciones (puede marcar "No sé" en cualquiera)
  3. Sistema aplica rate limiting (máx. 3/hora)
  4. IA verifica coherencia incluyendo respuestas del formulario
  5. Sistema aplica threshold antes de publicar
- **Flujo alternativo:** Sin conexión → reporte + respuestas se guardan localmente y se envían al restaurarse.
- **Resultado:** Reporte estructurado guardado internamente; publicado solo si supera el threshold. Identidad siempre anónima.

### CU-03: Confirmar o Desmentir Reporte Activo (tipo Waze)
- **Actor:** Ciudadano
- **Descripción:** Al ver un pin activo en el mapa, el usuario puede indicar:
  - ✅ **"Sigue ahí"** → el sistema extiende la vida del reporte 30 minutos adicionales y suma al contador de confirmaciones
  - ❌ **"Ya no está"** → si 3+ usuarios marcan esto, el reporte se retira del mapa
- **Resultado:** El mapa se mantiene actualizado con validación colectiva, sin depender exclusivamente de la IA.

### CU-04: Recibir Alerta en Tiempo Real
- **Actor:** Ciudadano (pasivo)
- **Descripción:** El sistema detecta al usuario en zona de riesgo vía geofencing (PostGIS) y envía push proactivo respetando el cooldown de 3 minutos.
- **Resultado:** El usuario recibe alerta con tipo, distancia y severidad del incidente más cercano.

### CU-05: Consultar Dashboard de Riesgo
- **Actor:** Ciudadano
- **Descripción:** El usuario busca una dirección y consulta índice de riesgo (0–100), predicción horaria, histórico por día/hora y noticias locales.
- **Resultado:** Visualización completa del riesgo de la zona consultada.

### CU-06: Comparar Rutas por Seguridad
- **Actor:** Ciudadano
- **Descripción:** El usuario ingresa origen y destino; el sistema dibuja en Leaflet.js dos rutas con colores según su índice de riesgo promedio (verde/amarillo/rojo) y tiempo estimado.
- **Resultado:** El usuario elige la ruta más segura antes de desplazarse.

### CU-07: Activar Botón de Pánico
- **Actor:** Ciudadano
- **Descripción:** Activación por 3 seg en app, 3 pulsaciones de volumen, o palabra clave de voz. El sistema graba en segundo plano, activa alarma fuerte (no silenciable con volumen), comparte ubicación en vivo y alerta al serenazgo.
- **Desactivación:** PIN de 4 dígitos desde notificación persistente, sin abrir la app.
- **Resultado:** Evidencia grabada, cifrada AES-256 y respaldada; alertas enviadas.

### CU-08: Configurar Pánico y Seguridad Personal
- **Actor:** Ciudadano
- **Descripción:** El usuario configura PIN de desactivación, palabra clave de voz, contacto de confianza y radio de alerta personal.
- **Resultado:** Configuración guardada cifrada en servidor.

### CU-09: Gestionar Incidentes (Autoridad)
- **Actor:** Supervisor
- **Descripción:** Visualiza incidentes activos (sin ver identidad de reportantes), puede ver las respuestas del formulario dinámico para evaluar gravedad, filtra y asigna unidades con un clic.
- **Resultado:** Incidente gestionado con trazabilidad completa.

### CU-10: Ver Predicciones y Patrones (Autoridad)
- **Actor:** Supervisor
- **Descripción:** El panel muestra predicciones de zonas de alto riesgo por IA para la próxima hora y día siguiente, junto a patrones criminales detectados (incluyendo patrones derivados de las respuestas del formulario, como zonas donde predomina "arma de fuego").
- **Resultado:** Información predictiva para patrullaje preventivo.

### CU-11: Exportar Reportes Estadísticos (Autoridad)
- **Actor:** Supervisor
- **Descripción:** Genera PDF/Excel con estadísticas incluyendo distribución de respuestas del formulario dinámico (ej: % de robos con arma, % que huyeron en vehículo) para informes al MININTER.
- **Resultado:** Archivo descargable sin datos personales de ciudadanos.

### CU-12: Verificar y Clasificar Reporte (IA)
- **Actor:** Módulo de IA (automático)
- **Descripción:** La IA valida coherencia cruzando la hora, ubicación, tipo de incidente **y las respuestas del formulario dinámico** (detecta incoherencias internas como severidad extrema con comportamiento tranquilo). Aplica threshold y clasifica severidad.
- **Resultado:** Reporte aprobado/rechazado en <5 segundos con severidad asignada.

---

## 4. REQUERIMIENTOS

### 4.1 Requerimientos Funcionales — App Móvil (Ciudadano)

| ID | Requerimiento | Prioridad |
|---|---|---|
| RF-01 | Registro e inicio de sesión con correo, Google o WhatsApp. Identidad cifrada internamente, anónima para el público | 🔴 CRÍTICA |
| RF-02 | Reporte de incidente en ≤10 seg: tipo + formulario dinámico + foto/audio/video opcional + GPS automático | 🔴 CRÍTICA |
| RF-02a | **Formulario dinámico estructurado:** 3–4 preguntas de opción múltiple adaptadas al tipo de incidente seleccionado | 🔴 CRÍTICA |
| RF-02b | El formulario siempre incluye la opción "No sé" en preguntas situacionales para no bloquear el reporte bajo estrés | 🔴 CRÍTICA |
| RF-02c | Las respuestas del formulario se almacenan como JSON estructurado y son visibles en el panel de autoridades (sin vincular a identidad del reportante) | 🟠 ALTA |
| RF-02d | Un reporte con formulario completo tiene mayor peso en el threshold de publicación que uno sin respuestas | 🟠 ALTA |
| RF-02e | Rate limiting: máximo 3 reportes por hora por cuenta | 🔴 CRÍTICA |
| RF-02f | Los reportes nunca incluyen nombres de personas ni establecimientos; solo coordenadas GPS y tipo de delito | 🔴 CRÍTICA |
| RF-03 | Notificación push a usuarios en radio 300m–1km tras superar el threshold de publicación | 🔴 CRÍTICA |
| RF-03a | Cooldown de notificaciones: máximo 1 push por tipo/zona cada 3 minutos por usuario | 🟠 ALTA |
| RF-03b | **Confirmación tipo Waze:** pin activo en el mapa muestra botones "✅ Sigue ahí" / "❌ Ya no está" | 🔴 CRÍTICA |
| RF-03c | 3+ usuarios marcan "Ya no está" → el pin se retira del mapa automáticamente | 🟠 ALTA |
| RF-03d | 3+ usuarios marcan misma respuesta crítica en el formulario (ej: "arma de fuego") → el sistema escala severidad automáticamente | 🟠 ALTA |
| RF-03e | Threshold de publicación: mínimo 2 reportes independientes en 15 min; 1 solo reporte no genera push | 🔴 CRÍTICA |
| RF-03f | Agrupación automática de reportes masivos: 50+ reportes del mismo punto en 5 min = un único evento con contador | 🟠 ALTA |
| RF-03g | Expiración automática: reportes sin confirmación desaparecen del mapa a los 30 minutos | 🟠 ALTA |
| RF-04 | Mapa en vivo con incidentes por tipo y severidad (leve/moderado/crítico) | 🔴 CRÍTICA |
| RF-05 | Botón de pánico: activación por 3 seg en app, 3 pulsaciones de volumen físico, o comando de voz configurable | 🔴 CRÍTICA |
| RF-05a | Desactivación del pánico mediante PIN de 4 dígitos desde la notificación persistente (sin abrir la app) | 🔴 CRÍTICA |
| RF-05b | Alarma sonora fuerte no silenciable con botones físicos de volumen durante el modo pánico | 🔴 CRÍTICA |
| RF-05c | Foreground Service: persiste aunque la app sea cerrada | 🔴 CRÍTICA |
| RF-05d | Cola offline: grabación continúa localmente si se pierde conexión | 🔴 CRÍTICA |
| RF-05e | PIN incorrecto 3 veces → alarma se mantiene + notificación al contacto de confianza | 🟠 ALTA |
| RF-05f | Grabación segmentada en bloques de 10 min, límite 60 min | 🟠 ALTA |
| RF-05g | Grabaciones cifradas AES-256 en servidor; accesibles solo por el usuario o con orden judicial | 🔴 CRÍTICA |
| RF-06 | Configuración: PIN de 4 dígitos, palabra clave de voz, contacto de confianza, radio de alerta | 🔴 CRÍTICA |
| RF-07 | Dashboard de riesgo: índice 0–100, últimos 5 incidentes, predicción por horas | 🔴 CRÍTICA |
| RF-08 | Búsqueda de dirección con índice de riesgo + predicción horaria + gráficos históricos | 🔴 CRÍTICA |
| RF-09 | Predicción probabilística de riesgo para cada hora del día (0h–23h) | 🔴 CRÍTICA |
| RF-10 | Gráficos históricos de incidentes por día de semana y hora | 🟠 ALTA |
| RF-11 | Feed de noticias de seguridad local filtradas por distrito, en tiempo real | 🟠 ALTA |
| RF-12 | **Comparador de rutas:** muestra dos rutas origen–destino coloreadas por nivel de riesgo (verde/amarillo/rojo) usando Leaflet.js + OpenRouteService | 🟠 ALTA |
| RF-13 | **Geofencing proactivo:** notificación automática cuando el usuario GPS entra en zona de riesgo alto (PostGIS `ST_DWithin()`, radio 500m) | 🟠 ALTA |
| RF-14 | Configuración personal: radio de alerta, tipos de incidentes de interés, horarios silenciosos | 🟠 ALTA |
| RF-15 | Estado del reporte: recibido → en atención → cerrado | 🟠 ALTA |
| RF-16 | Modo offline: guardar reporte + respuestas del formulario localmente y enviar al restaurarse conexión | 🟡 MEDIA |
| RF-17 | Sugerencia de rutas peatonales seguras evitando zonas con incidentes activos | 🟡 MEDIA |

### 4.2 Requerimientos Funcionales — Panel Web (Autoridades)

| ID | Requerimiento | Prioridad |
|---|---|---|
| RF-18 | Dashboard en tiempo real de reportes activos. Nunca muestra identidad de ciudadanos reportantes | 🔴 CRÍTICA |
| RF-19 | Vista de detalle de reporte: incluye respuestas del formulario dinámico (tipo de arma, número de agresores, dirección de huida, etc.) sin exponer la identidad del reportante | 🔴 CRÍTICA |
| RF-20 | Asignación de unidad a incidente con un clic; ciudadano ve confirmación de atención | 🔴 CRÍTICA |
| RF-21 | Mapa de calor histórico filtrable por distrito, semana, tipo de delito y franja horaria | 🟠 ALTA |
| RF-22 | Estadísticas de respuestas del formulario dinámico: ej. "65% de robos en Miraflores involucran arma de fuego", "40% de agresores huyen en vehículo" | 🟠 ALTA |
| RF-23 | Generación de reportes estadísticos exportables en PDF/Excel para MININTER (sin datos personales) | 🟠 ALTA |
| RF-24 | Predicciones de zonas de alto riesgo generadas por IA (próxima hora y día siguiente) | 🟠 ALTA |
| RF-25 | Detección de patrones criminales automáticos incluyendo patrones de respuestas del formulario (zonas con predominio de arma de fuego, zonas con alta reincidencia) | 🟠 ALTA |
| RF-26 | Filtros avanzados: tipo de delito, rango de fechas, estado de atención, nivel de confiabilidad | 🟡 MEDIA |

### 4.3 Requerimientos Funcionales — Módulo IA

| ID | Requerimiento | Prioridad |
|---|---|---|
| RF-27 | Verificación automática de coherencia en <5 seg, incluyendo **detección de incoherencias en las respuestas del formulario** (ej: severidad extrema + comportamiento tranquilo) | 🔴 CRÍTICA |
| RF-28 | Clasificación automática de severidad LEVE / MODERADO / CRÍTICO usando también las respuestas del formulario como features | 🔴 CRÍTICA |
| RF-29 | Aplicación de threshold de publicación antes de emitir notificaciones | 🔴 CRÍTICA |
| RF-30 | Predicción probabilística de riesgo por franja horaria (0h–23h) para cualquier zona | 🔴 CRÍTICA |
| RF-31 | Uso de respuestas del formulario dinámico como **features adicionales** en el modelo de predicción de riesgo y verificación de reportes | 🟠 ALTA |
| RF-32 | Detección de patrones criminales por zona, tipo y horario | 🟠 ALTA |
| RF-33 | Cruce de reportes con noticias locales para enriquecer índice de riesgo | 🟠 ALTA |
| RF-34 | Sistema de reputación interno: reportes verificados suman puntos; reportes falsos penalizan | 🟠 ALTA |
| RF-35 | Detección y filtrado automático de reportes duplicados | 🟡 MEDIA |
| RF-36 | Agrupación de reportes masivos del mismo punto en eventos únicos con contador | 🟠 ALTA |

### 4.4 Requerimientos No Funcionales

| ID | Categoría | Requerimiento | Métrica |
|---|---|---|---|
| RNF-01 | Rendimiento | Notificaciones push tras confirmación | <3 segundos |
| RNF-02 | Rendimiento | Actualización del mapa en tiempo real | <2 segundos latencia |
| RNF-03 | Rendimiento | Carga del dashboard de zona | <2 segundos |
| RNF-04 | Rendimiento | Respuesta de la IA de verificación | <5 segundos |
| RNF-05 | Rendimiento | Usuarios concurrentes en fase piloto | 10,000 usuarios |
| RNF-06 | Rendimiento | Consumo de datos en modo activo | <2 MB/hora |
| RNF-07 | Seguridad | Comunicación cifrada | TLS 1.3 / HTTPS |
| RNF-08 | Seguridad | Datos personales | Ley N° 29733 + Art. 8 |
| RNF-09 | Seguridad | Identidad del reportante: anónima para el público, cifrada internamente | AES-256 obligatorio |
| RNF-10 | Seguridad | Grabaciones del botón de pánico cifradas | AES-256 |
| RNF-11 | Seguridad | Acceso al panel de autoridades | 2FA obligatorio |
| RNF-12 | Seguridad | Expiración de tokens JWT / refresh | 1h / 30 días |
| RNF-13 | Seguridad | Encriptación de contraseñas | bcrypt costo ≥12 |
| RNF-14 | Seguridad | Log de accesos al panel web | IP + hora + usuario |
| RNF-15 | Seguridad | Términos y condiciones: responsabilidad legal del reporte al usuario | Obligatorio en registro |
| RNF-16 | Seguridad | Formulario dinámico nunca solicita datos personales del agresor | Obligatorio |
| RNF-17 | Anti-pánico | Threshold mínimo de publicación | 2 reportes / 15 min |
| RNF-18 | Anti-pánico | Rate limiting por usuario | Máx. 3/hora |
| RNF-19 | Anti-pánico | Cooldown de notificaciones push | 1 push / 3 min / tipo+zona |
| RNF-20 | Anti-pánico | Expiración de reportes sin confirmación | 30 minutos |
| RNF-21 | Formulario | Máximo de preguntas por tipo de incidente | 4 preguntas |
| RNF-22 | Formulario | Formato de preguntas | Opción múltiple exclusivamente |
| RNF-23 | Formulario | Almacenamiento de respuestas | JSON estructurado en PostgreSQL |
| RNF-24 | Formulario | Peso diferenciado: reporte con formulario completo vs. incompleto | Mayor peso en threshold |
| RNF-25 | Usabilidad | Completar reporte + formulario desde pantalla principal | ≤10 segundos / ≤4 toques |
| RNF-26 | Usabilidad | Accesible para usuarios con alfabetización digital básica | — |
| RNF-27 | Usabilidad | Tamaño mínimo de texto | 18pt |
| RNF-28 | Usabilidad | Idioma del MVP | Español (quechua: futuro) |
| RNF-29 | Compatibilidad | Versión mínima Android | 8.0 Oreo, 2GB RAM |
| RNF-30 | Compatibilidad | Tamaños de pantalla | 4.5" – 6.7" |
| RNF-31 | Disponibilidad | Disponibilidad mensual | ≥99.5% |
| RNF-32 | Disponibilidad | Cola offline para reportes y grabaciones | Obligatorio |
| RNF-33 | Escalabilidad | Escala horizontal para nuevas ciudades | Obligatorio |
| RNF-34 | Escalabilidad | Reentrenamiento del modelo IA sin interrumpir servicio | Cada 30 días |

---

## 5. STACK TECNOLÓGICO

### 5.1 Resumen por Capa

| Capa | Tecnología | Rol |
|---|---|---|
| **App Móvil** | Flutter | Código compartido Android/iOS; Foreground Services para pánico; formulario dinámico condicional |
| **Frontend Web** | React.js + TypeScript | Panel de autoridades reactivo con vista de respuestas del formulario |
| **Mapas** | Leaflet.js + OpenStreetMap | Mapa en vivo, geofencing visual, comparador de rutas coloreadas por riesgo |
| **Rutas** | OpenRouteService API | Cálculo de rutas para el comparador (gratuito, sin límites estrictos) |
| **Backend / API** | Node.js + Express | API REST + WebSockets + threshold engine + rate limiting |
| **Caché / Rate Limiting** | Redis (ioredis) | Conteo de reportes por usuario/zona en ventanas de tiempo |
| **Tiempo Real** | Socket.io | Notificaciones bidireccionales <100ms |
| **BD Tiempo Real** | Firebase Realtime Database | Coordenadas y reportes en vivo |
| **BD Histórica** | PostgreSQL + PostGIS | ACID, índices geoespaciales, geofencing (`ST_DWithin()`), respuestas del formulario en JSONB, identidad cifrada (pgcrypto AES-256) |
| **IA / ML Backend** | Python + FastAPI | Microservicio de verificación y predicción; consume features del formulario dinámico |
| **Modelos ML** | scikit-learn + XGBoost + Prophet | Isolation Forest (MVP) → XGBoost (avanzado); Random Forest + Prophet para predicción |
| **Noticias** | RSS scraping + BeautifulSoup | Scraping de RPP, El Comercio, La República |
| **Notificaciones Push** | Firebase Cloud Messaging (FCM) | Push multiplataforma integrado con Flutter |
| **Autenticación** | Firebase Auth + JWT | OAuth social; identidad cifrada AES-256 internamente |
| **Almacenamiento grabaciones** | GCP Cloud Storage + AES-256 | Grabaciones del botón de pánico cifradas y segmentadas |
| **Infraestructura** | Google Cloud Platform (GCP) | Escalable, cobertura en Perú, créditos académicos |
| **CI/CD** | GitHub Actions | Integración y despliegue automático |

### 5.2 Justificaciones Técnicas Clave

#### Formulario Dinámico — Flutter (frontend) + PostgreSQL JSONB (backend)
- En Flutter, la lógica condicional de preguntas es simple (`if tipoIncidente == 'robo' → mostrar preguntasRobo`)
- Las respuestas se guardan como **JSONB** en PostgreSQL, que permite consultas eficientes sobre campos JSON sin esquema rígido
- Permite agregar nuevos tipos de incidente con nuevas preguntas sin alterar el esquema de la base de datos

#### Geofencing — PostGIS `ST_DWithin()`
- Calcula si el usuario está dentro de un radio respecto a una zona de riesgo en milisegundos
- El GPS del usuario se evalúa cada 30 segundos desde el backend; no requiere procesamiento constante en el cliente
- `ST_DWithin(ubicacion_usuario, geom_zona, 500)` — 500 metros de radio por defecto

#### Comparador de Rutas — Leaflet.js + OpenRouteService
- OpenRouteService devuelve las coordenadas de la ruta como GeoJSON
- El backend consulta el índice de riesgo de cada punto de la ruta en PostGIS y calcula el promedio
- Leaflet dibuja la polilínea con `L.polyline()` coloreada según el índice de riesgo (verde <30, amarillo 30–60, rojo >60)

#### Redis — Rate Limiting y Threshold Engine
- Conteo de reportes por usuario en ventanas de tiempo (`INCR` + `EXPIRE`) sin sobrecargar PostgreSQL
- Conteo de reportes por zona/tipo en ventana de 15 min para evaluar el threshold de publicación en tiempo real

---

## 6. MÓDULO DE INTELIGENCIA ARTIFICIAL

> Esta sección explica qué algoritmos se usan, cuándo, por qué, y cuáles son sus entradas y salidas exactas.

### 6.1 Arquitectura del Módulo ML

```
App Móvil / Panel Web
        ↓
  Backend (Node.js)
  ├── Rate Limiting (Redis)
  ├── Threshold Engine (Redis)
  └── llamada HTTP interna al ML
        ↓
  Microservicio ML (Python + FastAPI)
  ├── POST /verificar-reporte  → Isolation Forest / XGBoost
  └── POST /predecir-riesgo    → Random Forest / Prophet
        ↓
  PostgreSQL + PostGIS (datos históricos + respuestas JSONB del formulario)
```

Si el ML falla, el backend opera con **reglas heurísticas como fallback** automático.

### 6.2 MÓDULO 1 — Verificador de Reportes

**Endpoint:** `POST /verificar-reporte`

#### Fase MVP: Isolation Forest

**Input (con respuestas del formulario dinámico):**
```json
{
  "hora_del_dia": 22,
  "dia_semana": 1,
  "lat": -12.0931,
  "lng": -77.0465,
  "tipo_incidente_encoded": 3,
  "tiene_evidencia": 1,
  "score_reputacion_usuario": 78,
  "incidentes_zona_ultima_semana": 12,
  "formulario": {
    "num_agresores": "2-3 personas",
    "tiene_arma": "arma de fuego",
    "sigue_en_zona": "huyó en vehículo",
    "direccion_huida": "norte"
  }
}
```

> La IA detecta incoherencias: si `severidad_reportada = CRÍTICO` pero `num_agresores = 1` + `tiene_arma = no` + `actitud = tranquila` → score de anomalía alto → posible rechazo.

**Output:**
```json
{
  "aprobado": true,
  "score_anomalia": -0.12,
  "score_confianza": 88,
  "severidad": "CRÍTICO",
  "razon_rechazo": null,
  "coherencia_formulario": "alta"
}
```

#### Fase Avanzada (Mes 6+): XGBoost Classifier
Cuando se acumulen 500+ reportes etiquetados (real/falso), XGBoost reemplaza a Isolation Forest con supervisión directa. Las respuestas del formulario se convierten en features categóricos codificados con `LabelEncoder`.

---

### 6.3 MÓDULO 2 — Predictor de Riesgo

**Endpoint:** `POST /predecir-riesgo`

#### Fase MVP: Random Forest Regressor

**Input (enriquecido con patrones del formulario):**
```json
{
  "lat": -12.0931,
  "lng": -77.0465,
  "hora_del_dia": 22,
  "dia_semana": 4,
  "es_feriado": false,
  "incidentes_zona_ultimas_24h": 5,
  "incidentes_zona_ultima_semana": 18,
  "pct_reportes_con_arma_zona": 0.65,
  "pct_agresores_en_vehiculo_zona": 0.40,
  "pct_reportes_activos_zona": 0.72
}
```

> Los campos `pct_*` se calculan agregando las respuestas del formulario dinámico por zona — información que sin el formulario sería imposible obtener automáticamente.

**Output:**
```json
{
  "indice_riesgo": 73.4,
  "nivel": "ALTO",
  "prediccion_proximas_24h": [45,38,31,28,25,22,20,24,35,51,62,68,71,73,70,65,60,55,58,65,73,75,72,68],
  "confianza": "modelo_ml",
  "tiempo_respuesta_ms": 280
}
```

#### Fase Avanzada (Mes 5+): Random Forest + Facebook Prophet
Prophet añade detección de tendencias a largo plazo, estacionalidad semanal y feriados nacionales peruanos que el RF no captura.

---

### 6.4 Tabla Resumen de Algoritmos por Fase

| Módulo | Fase MVP | Fase Avanzada | Trigger de cambio |
|---|---|---|---|
| **Verificador de Reportes** | Isolation Forest | XGBoost Classifier | 500+ reportes etiquetados |
| **Predictor de Riesgo** | Random Forest Regressor | RF + Facebook Prophet | 5,000+ registros propios (mes 5+) |
| **Dashboard Autoridades** | SQL + PostGIS puro | SQL + PostGIS puro | No cambia |

### 6.5 Impacto del Formulario Dinámico en la IA

| Sin formulario dinámico | Con formulario dinámico |
|---|---|
| Features: hora, zona, tipo | Features: hora, zona, tipo + arma, agresores, dirección huida, presencia activa |
| Precisión esperada MVP: ~65% | Precisión esperada MVP: ~75–80% |
| No detecta incoherencias internas | Detecta reportes donde la descripción contradice la severidad reportada |
| No genera estadísticas operativas | Genera inteligencia táctica: "en esta zona el 65% de robos usan arma de fuego" |

### 6.6 Reglas Heurísticas (Fallback sin ML)

```
SI zona = distrito_alta_criminalidad (INEI) AND hora > 20:00 → riesgo = ALTO
SI zona = distrito_alta_criminalidad AND hora <= 20:00       → riesgo = MODERADO
SI zona = distrito_baja_criminalidad AND hora > 20:00        → riesgo = MODERADO
SI zona = distrito_baja_criminalidad AND hora <= 20:00       → riesgo = BAJO

Escalada por formulario (sin ML):
SI 3+ usuarios marcan "arma de fuego"    → forzar severidad CRÍTICO
SI 3+ usuarios marcan "heridos visibles" → forzar CRÍTICO + alerta comisaría
SI 3+ usuarios marcan "sigue en zona"    → extender vida del reporte 30 min
```

### 6.7 Métricas de Evaluación

| Modelo | Métrica | Objetivo |
|---|---|---|
| Verificador | Precisión + Recall | Precisión > 80%, Recall > 75% |
| Predictor | MAE (Mean Absolute Error) | MAE < 12 puntos en escala 0–100 |
| Formulario | Tasa de completitud | >70% de reportes con formulario completo |

### 6.8 Reentrenamiento Mensual Automatizado

```
Día 1 de cada mes a las 2:00 AM:
  1. Cargar reportes del último mes desde PostgreSQL (incluye respuestas JSONB del formulario)
  2. Entrenar nuevo modelo con datos históricos completos
  3. Evaluar precisión del nuevo modelo vs. el actual
  4. Si mejor → reemplazar en producción (hot-swap sin interrumpir servicio)
  5. Si no → mantener actual y registrar alerta
```

---

## 7. ANEXO — LIBRERÍAS Y RECURSOS

### Librerías Python (microservicio ML)
```
fastapi==0.115.0
uvicorn==0.30.0
scikit-learn==1.5.0
pandas==2.2.0
numpy==1.26.0
xgboost==2.0.3
prophet==1.1.5
psycopg2-binary==2.9.9
sqlalchemy==2.0.30
joblib==1.4.0
```

### Librerías adicionales (Node.js backend)
```
ioredis          — rate limiting y threshold engine en Redis
express-rate-limit — middleware de rate limiting por IP/usuario
```

### APIs externas
- **OpenRouteService** — Cálculo de rutas para el comparador (gratuito): https://openrouteservice.org/

### Datos públicos para el MVP
- **INEI — Estadísticas de Seguridad Ciudadana:** https://www.inei.gob.pe/estadisticas/seguridad-ciudadana/
- **Lima Cómo Vamos — Seguridad:** https://www.limacomovamos.org/seguridad/
- **Datos Abiertos Municipalidad de Lima:** https://datosabiertos.munlima.gob.pe/
- **SERENAZGO Lima — Reportes históricos:** Solicitud de acceso vía Ley N° 27806

### Marco Legal Referenciado
- Ley N° 29733 — Protección de Datos Personales del Perú (Art. 8)
- Artículo 132 CP — Difamación
- Artículo 315 CP — Perturbación de la tranquilidad pública
- Ley N° 27806 — Transparencia y Acceso a la Información Pública

---

*AlertaZona — Análisis de Proyecto v1.4*
*Actualizado: 6 de abril de 2026*
*Cambios v1.4: Formulario dinámico estructurado por tipo de incidente (Structured Reporting) incorporado en procesos, restricciones, casos de uso, requerimientos, stack tecnológico y módulo IA. Confirmación tipo Waze ("Sigue ahí / Ya no está"). Escalada automática de severidad por respuestas del formulario. Comparador de rutas y geofencing proactivo documentados en detalle.*

---

Aquí tienes el roadmap completo. Te explico todo en detalle:
---
## Plan de 16 Semanas — 8 Sprints de 2 Semanas
### Sprint 1 — S1–S2: Cimientos
**Meta:** Que el equipo tenga un proyecto que "enciende" aunque no haga nada visible aún.
- Setup del repositorio GitHub + CI/CD con GitHub Actions
- Base de datos PostgreSQL + PostGIS configurada en GCP
- Autenticación Firebase (login con Google/correo)
- API REST base en Node.js con las rutas vacías definidas

> **Quién hace qué (3 personas):** P1 → infraestructura GCP + BD / P2 → API Node.js / P3 → Auth Firebase + Flutter base

***
### Sprint 2 — S3–S4: El Corazón del MVP
**Meta:** Poder reportar un incidente y verlo aparecer en el mapa. Es la demo mínima viable.
- Mapa en vivo con Leaflet.js mostrando pins
- Flujo completo de reporte (tipo + GPS + evidencia opcional)
- **Formulario dinámico para Robo y Accidente** (los 2 tipos del MVP)
- Threshold engine en Redis (conteo de reportes por zona/tiempo)

***
### Sprint 3 — S5–S6: Notificaciones y Geofencing
**Meta:** Que la app avise sola, sin que el usuario haga nada.
- Notificaciones push con FCM en <3 segundos
- **Confirmación tipo Waze** ("Sigue ahí / Ya no está") en cada pin
- Rate limiting (3 reportes/hora) + expiración de reportes a los 30 min
- **Geofencing proactivo** con PostGIS `ST_DWithin()`

***
### Sprint 4 — S7–S8: Inteligencia y Panel de Autoridades
**Meta:** Que la app "piense" y que las autoridades tengan su panel.
- Dashboard de riesgo con índice 0–100 + predicción horaria
- **Isolation Forest** para verificación de reportes (con features del formulario)
- **Random Forest** para predicción de riesgo por hora
- Panel web de autoridades v1: mapa de calor + lista de incidentes + asignación de unidades

***
### Sprint 5 — S9–S10: Botón de Pánico y Rutas
**Meta:** Las features de mayor impacto emocional para la demo.
- Botón de pánico con grabación en segundo plano + alarma fuerte
- **Android Foreground Service** (persiste si cierran la app)
- **Comparador de rutas** coloreadas por riesgo (Leaflet + OpenRouteService)
- Feed de noticias locales (scraping RPP/El Comercio)

> ⚠️ Este sprint es el más exigente técnicamente. Si hay retraso, el comparador de rutas se puede mover al S6.

***
### Sprint 6 — S11–S12: Formulario Completo y Modo Offline
**Meta:** Cerrar todos los tipos de reporte y hacer la app robusta.
- Formulario dinámico para los 5 tipos de incidente (Acoso, Extorsión, Persona Sospechosa)
- **Escalada automática de severidad** por respuestas del formulario
- Panel web de autoridades v2: filtros avanzados + exportación PDF/Excel
- Modo offline: guardar reportes localmente y sincronizar al restaurarse

***
### Sprint 7 — S13–S14: QA y Seguridad
**Meta:** Que todo lo construido funcione correctamente bajo presión.
- Pruebas de integración end-to-end (E2E)
- Reentrenamiento automático del modelo IA
- Ajustes de UX y accesibilidad (textos ≥18pt, flujos de 4 toques máx.)
- Revisión de seguridad: AES-256, 2FA en panel, auditoría de logs

***
### Sprint 8 — S15–S16: Buffer y Demo Final
**Meta:** Llegar a la presentación con todo funcionando.
- **S15 completa como buffer** para corregir bugs que hayan quedado del S7
- Preparación del script de demo (los 5 pasos del flujo ciudadano→IA→autoridad)
- Documentación técnica final

***
## Distribución Recomendada del Equipo
| Perfil | Rol principal | Sprints más intensos |
|---|---|---|
| **P1 — Backend/DevOps** | Node.js, Redis, PostgreSQL, GCP, CI/CD | S1–S4 |
| **P2 — Mobile** | Flutter, Foreground Service, UI/UX | S2–S6 |
| **P3 — IA/Data** | Python, FastAPI, Isolation Forest, Random Forest | S4–S7 |
| **P4 (si hay 4to)** | Panel web React + scraping + QA | S4–S8 |

> Con **3 personas**, P1 absorbe el scraping de noticias (S5) y P2 apoya en el panel web durante el S4. Es exigente pero lograble si no hay materias paralelas muy pesadas.