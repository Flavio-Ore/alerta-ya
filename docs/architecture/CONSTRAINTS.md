# CONSTRAINTS.md — Restricciones del MVP AlertaYa

> Estas restricciones son **no negociables** para el MVP.
> Claude Code debe verificar contra esta lista antes de implementar cualquier feature.

---

## RESTRICCIONES DE ALCANCE (MVP)

| # | Restricción | Impacto en código |
|---|-------------|-------------------|
| R01 | Solo Lima Metropolitana como zona piloto | Hardcodear bounding box de Lima en geofencing: `{lat: [-12.28, -11.77], lng: [-77.17, -76.78]}` |
| R02 | No gestión de despacho operativo de patrullas PNP | El panel autoridades solo asigna, no rastrea unidades en tiempo real |
| R03 | No integración de cámaras de videovigilancia | Sin endpoints de video externo |
| R04 | No módulo de denuncia formal ante MININTER | Solo exportación estadística, sin flujo de denuncia |
| R05 | No integración bancaria para fraude electrónico | Sin campos de datos financieros en ningún formulario |
| R06 | No versión web para ciudadanos | La web es SOLO para autoridades. Bloquear acceso ciudadano al panel web |
| R07 | Formulario dinámico MVP: solo **Robo/Asalto** y **Accidente de Tránsito** | Los otros 3 tipos (Acoso, Extorsión, Persona Sospechosa) se agregan en Sprint 6 |

---

## RESTRICCIONES DE THRESHOLD Y PUBLICACIÓN

```
NUNCA publicar un reporte con solo 1 fuente:
  1 reporte solo → guardar internamente, NO publicar, NO notificar

Reglas de publicación:
  2 reportes independientes en 15 min → publicar como LEVE, sin push
  3+ reportes en 15 min              → MODERADO + push a usuarios en radio
  5+ reportes en 20 min              → CRÍTICO + push + alerta comisaría

Escalada por formulario (sin esperar IA):
  3+ usuarios marcan "arma de fuego"    → forzar CRÍTICO
  3+ usuarios marcan "heridos visibles" → forzar CRÍTICO + alerta comisaría
  3+ usuarios marcan "sigue en zona"    → extender vida del reporte 30 min adicionales

Agrupación masiva:
  50+ reportes mismo punto en 5 min → consolidar en evento único con contador

Expiración:
  Reporte sin confirmación → eliminar del mapa a los 30 min
  Confirmación Waze "sigue ahí" → extender 30 min adicionales
  3+ usuarios marcan "ya no está" → retirar del mapa
```

**Implementación:** Toda esta lógica vive en `ThresholdEngine.ts` en el backend. Nunca en el cliente.

---

## RESTRICCIONES DE RATE LIMITING

```
Por cuenta de usuario:
  Máximo 3 reportes por hora

Por notificación push:
  Máximo 1 push del mismo tipo/zona cada 3 minutos por usuario (cooldown)

Geofencing cooldown:
  Si usuario ya recibió alerta de zona X → no volver a notificar por 3 min
```

**Implementación:** Redis con TTL para todos los rate limits.

---

## RESTRICCIONES DE ANONIMATO (CRÍTICAS — LEY N° 29733)

```
NUNCA exponer en ningún endpoint público:
  - Nombre, email, teléfono del reportante
  - UID de Firebase del reportante
  - Foto o descripción física del reportante
  - Historial de reportes vinculado a un usuario

SIEMPRE almacenar internamente:
  - Identidad cifrada con AES-256
  - Solo accesible con orden judicial
  - Log de acceso a datos sensibles

El panel de autoridades:
  - NUNCA muestra la identidad del reportante
  - Muestra: tipo de incidente, zona, hora, respuestas del formulario dinámico
  - Las respuestas del formulario son visibles pero SIN vincular a la identidad

El formulario dinámico:
  - NUNCA solicita: nombre del agresor, descripción facial, número de documento
  - Solo solicita: comportamiento, contexto situacional, datos de huida
```

**Verificación:** Antes de hacer CUALQUIER endpoint que retorne datos de reportantes, verificar que no exponga los campos prohibidos.

---

## RESTRICCIONES TÉCNICAS DE RENDIMIENTO

| Operación | Límite | Dónde se aplica |
|-----------|--------|-----------------|
| Notificación push tras confirmación | < 3 segundos | FCM + Cloud Run |
| Actualización del mapa en tiempo real | < 2 segundos latencia | WebSocket |
| Carga del dashboard de zona | < 2 segundos | React Query + caché |
| Respuesta de IA de verificación | < 5 segundos | FastAPI ML |
| Usuarios concurrentes fase piloto | 10,000 | Cloud Run autoscaling |
| Consumo de datos modo activo | < 2 MB/hora | App Flutter |

---

## RESTRICCIONES DEL FORMULARIO DINÁMICO

```
Máximo 4 preguntas por tipo de incidente
Solo opción múltiple — NUNCA texto libre
Siempre incluir "No sé" en preguntas situacionales
Respuestas almacenadas como JSON estructurado en PostgreSQL (columna JSONB)
Peso mayor en threshold si formulario está completo vs. incompleto
```

---

## RESTRICCIONES DEL BOTÓN DE PÁNICO

```
Debe funcionar como Android Foreground Service — persiste si cierran la app
La alarma NO puede silenciarse con botones físicos de volumen durante pánico activo
Desactivación SOLO por PIN de 4 dígitos desde notificación persistente
PIN incorrecto 3 veces → mantener alarma + notificar contacto de confianza
Grabación máxima: 60 minutos, en bloques de 10 min
Grabaciones cifradas AES-256 antes de subir a GCS
Sin conexión → grabar local, sincronizar al recuperar señal
```

---

## RESTRICCIONES LEGALES

```
Artículo 132 CP — Difamación:
  Reportes solo referencian coordenadas GPS y tipo de delito
  NUNCA nombres de personas ni establecimientos comerciales

Artículo 315 CP — Perturbación de la tranquilidad pública:
  El threshold de 2 reportes mínimos reduce el riesgo de pánico colectivo

Ley N° 29733 — Protección de Datos Personales:
  Cumplimiento estricto para todos los datos de usuarios
  Los exportes para MININTER no pueden incluir datos personales

Ley N° 27806 — Transparencia:
  Datos históricos disponibles para solicitud via esta ley
```
