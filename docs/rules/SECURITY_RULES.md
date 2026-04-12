# SECURITY_RULES.md — Reglas de Seguridad y Privacidad

> LEER ANTES de implementar auth, reportes, pánico, o cualquier endpoint.
> Incumplir estas reglas viola la Ley N° 29733 y puede poner en riesgo la vida de reportantes.

---

## ANONIMATO DEL REPORTANTE (CRÍTICO)

### Qué NUNCA puede salir de la base de datos hacia la API pública
```
❌ userId (Firebase UID)
❌ email del reportante
❌ nombre o alias del reportante
❌ historial de reportes vinculado a un usuario específico
❌ dirección IP del reportante
❌ device fingerprint
❌ timestamp exacto del primer reporte (solo "hace N min")
```

### Qué SÍ se puede mostrar en endpoints públicos y panel de autoridades
```
✅ Tipo de incidente
✅ Coordenadas GPS del incidente (zona, no del reportante)
✅ Distrito
✅ Severidad
✅ Número de reportes y confirmaciones (count, no quiénes)
✅ Respuestas del formulario dinámico de forma AGREGADA
   (ej: "2 de 3 reportaron arma de fuego" — nunca "el usuario X marcó arma")
✅ Timestamp relativo ("hace 7 min")
```

### Cómo implementar correctamente
```typescript
// ❌ MAL — expone userId
const incident = await prisma.report.findMany({
  select: { userId: true, formData: true, lat: true }
});

// ✅ BIEN — proyección sin identidad
const incident = await prisma.incident.findMany({
  select: {
    id: true, type: true, severity: true,
    lat: true, lng: true, district: true,
    confirmCount: true, reportCount: true,
    expiresAt: true
    // formData se agrega, nunca se expone el reporte individual
  }
});
```

---

## AUTENTICACIÓN Y AUTORIZACIÓN

### App móvil — ciudadanos
```
- Firebase Auth (Google, Email, WhatsApp)
- Token JWT de Firebase validado en CADA request al backend
- Middleware de auth obligatorio en todos los endpoints POST/PUT/DELETE
- Los endpoints GET de incidentes activos son públicos (solo lectura)
- Guardar token en SecureStorage (Flutter) — nunca en SharedPreferences
```

### Panel web — autoridades
```
- Firebase Auth + verificación de rol en Firestore
- Rol "AUTHORITY" requerido — ciudadano normal → 403 inmediato
- 2FA obligatorio (TOTP via Firebase MFA)
- Sesión expira en 8 horas — renovar con refresh token
- AuthGuard en TODAS las rutas del panel sin excepción
```

### Rate limiting en backend
```typescript
// Aplicar en este orden en cada request de reporte:
// 1. Verificar token Firebase (auth middleware)
// 2. Verificar rate limit en Redis: max 3 reportes/hora por userId
// 3. Si pasa → procesar reporte
// 4. Actualizar contador en Redis con TTL 3600s

const RATE_LIMIT_KEY = `rate:report:${userId}`;
const count = await redis.incr(RATE_LIMIT_KEY);
if (count === 1) await redis.expire(RATE_LIMIT_KEY, 3600);
if (count > MAX_REPORTS_PER_HOUR) throw new AppError(429, 'Límite de reportes por hora alcanzado');
```

---

## GRABACIONES DEL BOTÓN DE PÁNICO

```
ANTES de subir a Google Cloud Storage:
  1. Cifrar con AES-256 en el dispositivo del usuario
  2. Generar IV único por bloque de grabación
  3. Subir con metadata de cifrado

En GCS:
  - Bucket privado — sin acceso público nunca
  - Nombre del archivo: UUID aleatorio (no userId, no timestamp legible)
  - IAM: solo Cloud Run service account tiene acceso

Acceso posterior:
  - Solo el usuario autenticado puede solicitar sus propias grabaciones
  - Con orden judicial: proceso manual con aprobación de admin
  - Logging de CADA acceso a grabaciones
```

```dart
// Flutter — cifrar antes de subir
Future<Uint8List> encryptAES256(Uint8List data, String keyBase64) async {
  final key = encrypt.Key.fromBase64(keyBase64);
  final iv = encrypt.IV.fromSecureRandom(16);
  final encrypter = encrypt.Encrypter(encrypt.AES(key));
  final encrypted = encrypter.encryptBytes(data, iv: iv);
  // Prepend IV al ciphertext para poder desencriptar después
  return Uint8List.fromList([...iv.bytes, ...encrypted.bytes]);
}
```

---

## DATOS EN TRÁNSITO

```
- HTTPS/TLS 1.3 obligatorio en todos los endpoints
- WebSocket sobre WSS (TLS)
- Certificate pinning en la app Flutter (producción)
- Headers de seguridad via Helmet en Express:
    Content-Security-Policy
    X-Frame-Options: DENY
    X-Content-Type-Options: nosniff
    Strict-Transport-Security
```

---

## LOGGING (QUÉ NUNCA LOGGEAR)

```
❌ Tokens de acceso o refresh tokens
❌ Contraseñas o PINs
❌ userId del reportante en logs de incidentes
❌ Coordenadas GPS del usuario en logs generales
❌ Contenido de grabaciones de pánico
❌ Datos del formulario dinámico vinculados a userId

✅ SÍ loggear:
  - Timestamp + endpoint + status code
  - Error messages (sin datos sensibles)
  - Rate limit hits (con hash del userId, no el uid real)
  - Performance metrics
```

---

## FORMULARIO DINÁMICO — RESTRICCIONES DE DATOS

```
El formulario NUNCA solicita:
  ❌ Nombre del agresor
  ❌ Descripción facial (altura, complexión, color de piel)
  ❌ Número de documento del agresor
  ❌ Matrícula del vehículo del agresor
  ❌ Nombre del establecimiento

El formulario SÍ solicita (datos de comportamiento/contexto):
  ✅ Número aproximado de personas (rango)
  ✅ Tipo de arma (categoría general)
  ✅ ¿Sigue en la zona?
  ✅ Dirección de huida (punto cardinal)
  ✅ Comportamiento observado (categoría)
```

---

## CHECKLIST ANTES DE HACER MERGE

```
□ Ningún endpoint nuevo expone userId ni datos de identidad del reportante
□ Todos los endpoints autenticados tienen middleware de auth
□ Rate limiting aplicado donde corresponde
□ Datos sensibles cifrados en reposo (AES-256)
□ No hay datos personales en logs
□ Variables de entorno en .env.example (sin valores reales)
□ Tests de seguridad corriendo para nuevos endpoints
□ El formulario dinámico no solicita datos prohibidos
□ Panel de autoridades no muestra identidad del reportante
```
