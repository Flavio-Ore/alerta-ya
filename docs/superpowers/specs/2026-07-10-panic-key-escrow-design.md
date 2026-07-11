# Key escrow para grabaciones de pánico — diseño

Fecha: 2026-07-10

## Problema

Las grabaciones de audio del botón de pánico se cifran en el dispositivo con AES-256-CBC.
La clave se genera y vive únicamente en `flutter_secure_storage` del móvil, y se borra al
desactivar el modo pánico (`audio_recording_service.dart`, método `stop()`). El audio cifrado
sube a Firebase Storage (backed por GCS). Como resultado, **nadie puede volver a descifrar
esas grabaciones**: ni el backend ni la plataforma web de autoridades tienen la clave.

Se necesita un mecanismo de key escrow que permita a usuarios autorizados (rol `AUTHORITY`/
`ADMIN`) recuperar la clave y descifrar/reproducir el audio desde la web, sin debilitar la
seguridad del sistema ni exponer las claves en ningún punto del camino.

## Hallazgos del flujo actual (contexto)

- `mobile/lib/core/utils/encryption_util.dart`: AES-256-CBC, **sin autenticación** (no hay
  HMAC ni GCM) — un blob alterado en Storage no se detecta al descifrar.
- `mobile/lib/features/panic/data/services/audio_recording_service.dart`: la clave es
  **por dispositivo**, se reutiliza entre sesiones si no se borra explícitamente.
- `stop()` borra la clave (línea ~88) **antes** de que terminen de subirse todos los bloques
  (el upload es fire-and-forget) — race condition que puede perder la clave de bloques que
  ni siquiera terminaron de subir.
- Backend (`api/`, Node/TS/Bun/Express/Prisma/Postgres+PostGIS): `PanicSession.recordingUrls`
  nunca se puebla — no hay código que asocie las URLs de Storage a la sesión. La web de
  autoridades no tiene forma de ubicar los audios de una sesión aunque tuviera la clave.
- Auth: Firebase Admin SDK + custom claims (`AUTHORITY`, `ADMIN`), ya con middleware
  (`authority.middleware.ts`).
- No hay KMS/Vault en uso; todo secreto vive en variables de entorno. El proyecto ya está
  en GCP, por lo que Cloud KMS es la opción natural.

## Decisiones de diseño

- **Acceso**: rol `AUTHORITY`/`ADMIN` existente alcanza (sin doble aprobación por ahora).
- **Descifrado**: ocurre en el navegador (WebCrypto), nunca en el backend. El backend jamás
  ve el audio en claro.
- **Transporte de la clave**: envoltura asimétrica en el cliente (RSA-OAEP-256 respaldado por
  Cloud KMS). El backend nunca ve la clave AES en claro en tránsito — solo el ciphertext
  envuelto.
- **Ciclo de vida**: clave AES-256 nueva por sesión (no más reuso por dispositivo), escrow
  ANTES de empezar a grabar. La clave local no se borra hasta confirmar upload completo +
  escrow confirmado por el backend.
- **Modo de cifrado**: se migra de AES-256-CBC a **AES-256-GCM** (cifrado autenticado) como
  parte de este cambio.
- **Wiring de URLs**: se agrega registro de bloques subidos al backend (`RecordingBlock`),
  resolviendo el gap de `recordingUrls`.
- **UI web de autoridades**: fuera de alcance construirla; este diseño define el contrato
  (endpoints) que esa UI deberá consumir.

## Arquitectura

```
Cloud KMS (RSA-OAEP-256, HSM-backed)
  └─ clave privada: nunca sale de KMS
  └─ clave pública: se sirve al móvil para envolver

Móvil (por sesión de pánico):
  1. Genera clave AES-256 nueva (una por sesión)
  2. Pide la pública KMS actual al backend (GET /panic/escrow/public-key, cacheable)
  3. Envuelve la AES-key con RSA-OAEP-256 -> "wrapped key"
  4. Sube el wrapped key al backend ANTES de empezar a grabar
     (POST /panic/sessions/:id/escrow-key)
  5. Graba en bloques con AES-256-GCM
  6. Por cada bloque subido a Storage, avisa al backend
     (POST /panic/sessions/:id/blocks)
  7. Solo borra la clave local cuando: todos los bloques subieron Y
     el backend confirmó el escrow

Backend (Node/Express/Prisma):
  - Nunca ve la clave AES en claro (solo el wrapped key, ciphertext)
  - Guarda wrapped key + metadata KMS en PanicSessionKey
  - Guarda bloques subidos en RecordingBlock

Autoridad (web, UI fuera de alcance):
  1. Pide acceso a una sesión (rol AUTHORITY/ADMIN, middleware existente)
  2. Backend llama KMS.asymmetricDecrypt(wrappedKey) -> AES key efímera en memoria,
     la devuelve por TLS + URLs firmadas de corta duración (15 min) a los bloques
  3. El navegador descarga los bloques cifrados directo de Storage y descifra
     client-side con WebCrypto (AES-GCM)
  4. Cada acceso queda registrado en KeyAccessAudit
```

La clave nunca queda en texto plano en disco (ni backend ni DB): en tránsito viaja envuelta
o por TLS, en reposo en DB queda envuelta con KMS, y en el servidor solo existe en memoria
durante el request de acceso de la autoridad.

## Backend — modelo de datos

```prisma
model PanicSessionKey {
  id             String   @id @default(uuid())
  panicSessionId String   @unique
  panicSession   PanicSession @relation(fields: [panicSessionId], references: [id])
  wrappedKey     Bytes         // AES key envuelta con RSA-OAEP-256
  kmsKeyName     String        // resource name completo de la KMS key
  kmsKeyVersion  String
  algorithm      String        // "RSA_OAEP_256"
  createdAt      DateTime @default(now())
}

model RecordingBlock {
  id             String   @id @default(uuid())
  panicSessionId String
  panicSession   PanicSession @relation(fields: [panicSessionId], references: [id])
  blockIndex     Int
  storagePath    String        // path en Storage, no URL pública
  uploadedAt     DateTime @default(now())

  @@unique([panicSessionId, blockIndex])
}

model KeyAccessAudit {
  id             String   @id @default(uuid())
  panicSessionId String
  requestedById  String        // User.id de la autoridad
  requestedAt    DateTime @default(now())
  ipAddress      String?
  result         String        // "SUCCESS" | "DENIED" | "ERROR"
}
```

`RecordingBlock` reemplaza al `recordingUrls String[]` que nunca se pobló. Guarda el *path*
de Storage, no una URL pública — el acceso real usa signed URLs generadas on-demand.

## Backend — endpoints nuevos

Todos bajo `/panic/sessions/:id/...`, reusando `authMiddleware` existente.

| Método | Ruta | Quién | Qué hace |
|---|---|---|---|
| `GET` | `/panic/escrow/public-key` | dueño de sesión | Devuelve la pública KMS activa (PEM) + `keyVersion`. |
| `POST` | `/panic/sessions/:id/escrow-key` | dueño de sesión | Recibe `{ wrappedKey, kmsKeyVersion, algorithm }`, crea `PanicSessionKey`. Idempotente (409 si ya existe). |
| `POST` | `/panic/sessions/:id/blocks` | dueño de sesión | Recibe `{ blockIndex, storagePath }`, upsert en `RecordingBlock`. |
| `POST` | `/panic/sessions/:id/recordings/access` | `AUTHORITY`/`ADMIN` | Llama `KMS.asymmetricDecrypt(wrappedKey)`, arma signed URLs (TTL 15 min), devuelve `{ aesKey, blocks: [{index, url}] }`. Escribe en `KeyAccessAudit` siempre (éxito o error). |

## Backend — Cloud KMS

- `CryptoKey` de propósito `ASYMMETRIC_DECRYPT`, algoritmo `RSA_DECRYPT_OAEP_3072_SHA256`
  (o 4096), en el mismo proyecto GCP ya usado (`GCP_PROJECT_ID`).
- IAM: solo la service account del backend tiene `roles/cloudkms.cryptoKeyDecrypter`. La
  pública se sirve libremente (`roles/cloudkms.publicKeyViewer`).
- Cloud Audit Logs registra automáticamente cada `Decrypt` — bitácora independiente de
  `KeyAccessAudit`, no alterable por el backend. Correlacionable por timestamp/sessionId.

## Móvil — cambios

**`encryption_util.dart`** (CBC → GCM):
- `generateKey()`: sin cambios, pero se invoca una vez por sesión.
- `encrypt()`: IV de 12 bytes, modo `AESMode.gcm`. Formato del blob:
  `IV(12) || ciphertext || tag(16)`.
- `decrypt()` (nuevo): separa IV/tag, valida el tag automáticamente — un blob alterado
  lanza `AEADBadTagException` en vez de dar basura silenciosa.

**`audio_recording_service.dart`** — reordenamiento del ciclo de vida:

```
start(sessionId):
  1. key = EncryptionUtil.generateKey()          // nueva por sesión
  2. publicKeyPem = EscrowApi.fetchPublicKey()    // GET /panic/escrow/public-key
  3. wrappedKey = EncryptionUtil.wrapKeyRsaOaep(key, publicKeyPem)
  4. await EscrowApi.submitEscrowKey(sessionId, wrappedKey)  // con reintentos, no bloquea
     el arranque de la grabación si falla; marca sesión "pending_escrow" localmente
  5. _storage.write(_kEncryptionKey, key)
  6. arranca la grabación

_stopCurrentBlock(): cifra con GCM en vez de CBC (sin otros cambios de lógica)

al confirmar upload de cada bloque:
  EscrowApi.registerBlock(sessionId, blockIndex, storagePath)  // con reintentos

stop():
  1. espera uploads pendientes (deja de ser fire-and-forget)
  2. confirma escrow-key subido con éxito (reintenta con backoff si sigue pending)
  3. solo entonces: _storage.delete(_kEncryptionKey)
```

Resiliencia offline: si escrow o registro de bloques no se completan antes de cerrar la
app, quedan en cola local y se reintentan con conectividad — la clave nunca se borra sin
confirmación del backend.

## Descifrado en el navegador (WebCrypto)

1. La autoridad pide `POST /panic/sessions/:id/recordings/access` → recibe
   `{ aesKey (base64), blocks: [{index, url}] }` por HTTPS.
2. `aesKey` se importa con `crypto.subtle.importKey('raw', ..., 'AES-GCM', false, ['decrypt'])`
   — `extractable: false`.
3. Por cada bloque: `fetch(signedUrl)` → separar `IV(12) || ciphertext || tag(16)` →
   `crypto.subtle.decrypt({name:'AES-GCM', iv}, key, ciphertextConTag)`.
4. El resultado se arma en un `Blob` y se reproduce con `<audio>` vía
   `URL.createObjectURL` — nunca toca el backend ni se persiste en disco.
5. La clave vive solo en memoria del tab; nunca en `localStorage`/`sessionStorage`.

## Riesgos y mitigaciones

| Riesgo | Mitigación |
|---|---|
| Abuso interno (autoridad escucha sin causa) | `KeyAccessAudit` + Cloud Audit Logs de KMS, independientes entre sí. Trazabilidad forense, no prevención. |
| Compromiso de la DB (Postgres) | Wrapped key es inútil sin la privada de KMS — un dump no sirve de nada. |
| Compromiso del backend en runtime | La clave en claro solo existe en memoria durante el request de acceso, nunca se loguea ni persiste. Reduce la ventana, no la elimina. |
| Pérdida de "zero-knowledge" | Cambio de postura de privacidad, no solo técnico: hoy nadie puede escuchar los audios; con escrow, cualquier AUTHORITY puede. Debe reflejarse en términos/consentimiento de la app — decisión de producto, fuera de este doc. |
| Red inestable en el momento del escrow | Reintentos con backoff + la clave no se borra hasta confirmar. Peor caso: clave queda local hasta haber señal. |
| Rotación de la KMS key | `kmsKeyVersion` guardado por sesión permite múltiples versiones activas sin romper sesiones viejas. |

## Fuera de alcance

- UI de la plataforma web de autoridades (reproductor, botón de solicitud) — este doc
  define el contrato de endpoints que esa UI debe consumir.
- Doble aprobación / four-eyes para el acceso a claves.
- Retención/expiración automática de audios o claves escrow.
