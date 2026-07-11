# Panic Key Escrow Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Permitir que autoridades (`AUTHORITY`/`ADMIN`) descifren y escuchen grabaciones de pánico desde la web, mediante key escrow con Cloud KMS, sin que el backend vea nunca la clave AES ni el audio en claro.

**Architecture:** Envelope encryption de dos capas — Cloud KMS (RSA-OAEP-256, HSM-backed) como raíz de confianza; el móvil envuelve la clave AES-256-GCM de cada sesión con la pública KMS antes de grabar y la sube al backend (que nunca ve la clave en claro); una autoridad autorizada pide acceso y el backend desenvuelve vía `KMS.asymmetricDecrypt`, entrega la clave por TLS + URLs firmadas, y el navegador descifra client-side con WebCrypto.

**Tech Stack:** Backend: Node/TypeScript/Bun/Express/Prisma/PostgreSQL, Vitest+Supertest, `@google-cloud/kms`. Mobile: Flutter/Dart, `encrypt` (AES-GCM), `pointycastle`+`basic_utils` (RSA-OAEP), Dio, `injectable`/`get_it`, `flutter_test`.

## Global Constraints

- Modo de cifrado: **AES-256-GCM** (reemplaza CBC), IV de 12 bytes, formato de blob `IV(12) || ciphertext || tag(16)`.
- Wrap de clave: **RSA-OAEP-SHA256**, algoritmo reportado al backend siempre como el literal `'RSA_OAEP_256'`.
- El backend **nunca** debe loguear ni persistir la clave AES en claro — solo el wrapped key (Bytes) y, efímeramente en memoria, durante `POST /panic/sessions/:id/recordings/access`.
- Cada acceso a `POST /panic/sessions/:id/recordings/access` debe quedar registrado en `KeyAccessAudit`, incluso si falla.
- Todo endpoint nuevo bajo `/panic/...` reutiliza `authMiddleware` existente (`api/src/core/middleware/auth.middleware.ts`); el de liberación de clave añade `authorityMiddleware` (`api/src/core/middleware/authority.middleware.ts`).
- Sin contenedor DI en backend: dependencias inyectadas manualmente por objeto `deps`, instanciadas a nivel de módulo en el controller (patrón existente en `panic.controller.ts`).
- Sin mocktail/mockito en mobile: tests mobile usan fakes manuales que implementan la interfaz abstracta correspondiente (patrón `panic_location_tracker_test.dart`).
- Comando de tests backend: `cd api && bun run test` (Vitest). Comando de tests mobile: `cd mobile && flutter test`.

---

## Task 1: Cliente Cloud KMS

**Files:**
- Modify: `api/src/core/config/env.ts:18-20`
- Modify: `api/.env.example`
- Create: `api/src/core/config/kms.ts`
- Test: `api/src/core/config/__tests__/kms.test.ts`
- Modify: `api/package.json` (dependencia `@google-cloud/kms`)

**Interfaces:**
- Produces: `getEscrowPublicKey(): Promise<{ publicKeyPem: string; keyVersion: string }>`, `unwrapEscrowKey(wrappedKey: Buffer, keyVersion: string): Promise<Buffer>` — usados por Task 6 (controller) y Task 5 (usecase).

- [ ] **Step 1: Agregar la dependencia**

Run: `cd api && bun add @google-cloud/kms`

- [ ] **Step 2: Agregar las variables de entorno**

Editar `api/src/core/config/env.ts`, reemplazando:
```typescript
  // Google Cloud Storage
  GCS_BUCKET_NAME: z.string().optional(),
  GCP_PROJECT_ID: z.string().optional(),
```
por:
```typescript
  // Google Cloud Storage
  GCS_BUCKET_NAME: z.string().optional(),
  GCP_PROJECT_ID: z.string().optional(),

  // Cloud KMS — escrow de claves de cifrado de grabaciones de pánico
  KMS_PROJECT_ID: z.string(),
  KMS_LOCATION_ID: z.string().default('global'),
  KMS_KEY_RING_ID: z.string().default('panic-escrow'),
  KMS_KEY_ID: z.string().default('panic-escrow-key'),
  KMS_KEY_VERSION: z.string().default('1'),
```

Agregar al final de `api/.env.example`:
```
# Cloud KMS — escrow de claves de cifrado de grabaciones de pánico
KMS_PROJECT_ID=tu-proyecto-gcp
KMS_LOCATION_ID=global
KMS_KEY_RING_ID=panic-escrow
KMS_KEY_ID=panic-escrow-key
KMS_KEY_VERSION=1
```

- [ ] **Step 3: Escribir el test que falla**

Crear `api/src/core/config/__tests__/kms.test.ts`:
```typescript
import { describe, it, expect, vi, beforeEach } from 'vitest';

const getPublicKeyMock = vi.fn();
const asymmetricDecryptMock = vi.fn();

vi.mock('@google-cloud/kms', () => ({
  KeyManagementServiceClient: vi.fn().mockImplementation(() => ({
    getPublicKey: getPublicKeyMock,
    asymmetricDecrypt: asymmetricDecryptMock,
  })),
}));

vi.mock('../env', () => ({
  env: {
    KMS_PROJECT_ID: 'test-project',
    KMS_LOCATION_ID: 'global',
    KMS_KEY_RING_ID: 'panic-escrow',
    KMS_KEY_ID: 'panic-escrow-key',
    KMS_KEY_VERSION: '1',
  },
}));

describe('kms', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('getEscrowPublicKey devuelve el PEM y la versión configurada', async () => {
    getPublicKeyMock.mockResolvedValue([
      { pem: '-----BEGIN PUBLIC KEY-----\nABC\n-----END PUBLIC KEY-----\n' },
    ]);
    const { getEscrowPublicKey } = await import('../kms');

    const result = await getEscrowPublicKey();

    expect(result.keyVersion).toBe('1');
    expect(result.publicKeyPem).toContain('BEGIN PUBLIC KEY');
    expect(getPublicKeyMock).toHaveBeenCalledWith({
      name: 'projects/test-project/locations/global/keyRings/panic-escrow/cryptoKeys/panic-escrow-key/cryptoKeyVersions/1',
    });
  });

  it('getEscrowPublicKey lanza si KMS no devuelve PEM', async () => {
    getPublicKeyMock.mockResolvedValue([{ pem: null }]);
    const { getEscrowPublicKey } = await import('../kms');

    await expect(getEscrowPublicKey()).rejects.toThrow();
  });

  it('unwrapEscrowKey devuelve el buffer plaintext', async () => {
    asymmetricDecryptMock.mockResolvedValue([{ plaintext: Buffer.from('clave-secreta') }]);
    const { unwrapEscrowKey } = await import('../kms');

    const result = await unwrapEscrowKey(Buffer.from('wrapped'), '1');

    expect(result.toString()).toBe('clave-secreta');
    expect(asymmetricDecryptMock).toHaveBeenCalledWith({
      name: 'projects/test-project/locations/global/keyRings/panic-escrow/cryptoKeys/panic-escrow-key/cryptoKeyVersions/1',
      ciphertext: Buffer.from('wrapped'),
    });
  });

  it('unwrapEscrowKey lanza si KMS devuelve plaintext vacío', async () => {
    asymmetricDecryptMock.mockResolvedValue([{ plaintext: null }]);
    const { unwrapEscrowKey } = await import('../kms');

    await expect(unwrapEscrowKey(Buffer.from('wrapped'), '1')).rejects.toThrow();
  });
});
```

- [ ] **Step 2: Correr el test y verificar que falla**

Run: `cd api && bun run test kms.test.ts`
Expected: FAIL — `Cannot find module '../kms'`

- [ ] **Step 4: Implementar `kms.ts`**

Crear `api/src/core/config/kms.ts`:
```typescript
import { KeyManagementServiceClient } from '@google-cloud/kms';

import { env } from './env';

const client = new KeyManagementServiceClient();

function keyVersionName(version: string): string {
  return `projects/${env.KMS_PROJECT_ID}/locations/${env.KMS_LOCATION_ID}/keyRings/${env.KMS_KEY_RING_ID}/cryptoKeys/${env.KMS_KEY_ID}/cryptoKeyVersions/${version}`;
}

export async function getEscrowPublicKey(): Promise<{ publicKeyPem: string; keyVersion: string }> {
  const version = env.KMS_KEY_VERSION;
  const [publicKey] = await client.getPublicKey({ name: keyVersionName(version) });
  if (!publicKey.pem) {
    throw new Error('Cloud KMS no devolvió una clave pública PEM');
  }
  return { publicKeyPem: publicKey.pem, keyVersion: version };
}

export async function unwrapEscrowKey(wrappedKey: Buffer, keyVersion: string): Promise<Buffer> {
  const [result] = await client.asymmetricDecrypt({
    name: keyVersionName(keyVersion),
    ciphertext: wrappedKey,
  });
  if (!result.plaintext) {
    throw new Error('Cloud KMS no pudo desenvolver la clave (respuesta vacía)');
  }
  return Buffer.from(result.plaintext as Uint8Array);
}
```

- [ ] **Step 5: Correr el test y verificar que pasa**

Run: `cd api && bun run test kms.test.ts`
Expected: PASS (4 tests)

- [ ] **Step 6: Commit**

```bash
git add api/src/core/config/kms.ts api/src/core/config/__tests__/kms.test.ts api/src/core/config/env.ts api/.env.example api/package.json
git commit -m "feat(api): agrega cliente Cloud KMS para escrow de claves de pánico"
```

---

## Task 2: Modelo de datos — migración Prisma

**Files:**
- Modify: `api/prisma/schema.prisma:142-156`

**Interfaces:**
- Produces: modelos Prisma `PanicSessionKey`, `RecordingBlock`, `KeyAccessAudit` — usados por Tasks 3, 4, 5.

- [ ] **Step 1: Editar el schema**

En `api/prisma/schema.prisma`, reemplazar el modelo `PanicSession` actual:
```prisma
model PanicSession {
  id            String      @id @default(uuid())
  userId        String
  startedAt     DateTime    @default(now())
  endedAt       DateTime?
  recordingUrls String[]    // GCS URLs — cifradas AES-256
  lat           Float
  lng           Float
  status        PanicStatus @default(ACTIVE)
  deactivatedBy String?     // "pin" | "timeout"
  user          User        @relation(fields: [userId], references: [id])
  locationPoints PanicLocationPoint[]

  @@map("panic_sessions")
}
```
por:
```prisma
model PanicSession {
  id            String      @id @default(uuid())
  userId        String
  startedAt     DateTime    @default(now())
  endedAt       DateTime?
  recordingUrls String[]    // GCS URLs — cifradas AES-256 (legacy, ver RecordingBlock)
  lat           Float
  lng           Float
  status        PanicStatus @default(ACTIVE)
  deactivatedBy String?     // "pin" | "timeout"
  user          User        @relation(fields: [userId], references: [id])
  locationPoints PanicLocationPoint[]
  escrowKey      PanicSessionKey?
  recordingBlocks RecordingBlock[]

  @@map("panic_sessions")
}

// Clave AES-256 de la sesión, envuelta con la pública RSA-OAEP-256 de Cloud KMS.
// El backend nunca guarda ni ve la clave en claro — solo este ciphertext.
model PanicSessionKey {
  id             String   @id @default(uuid())
  panicSessionId String   @unique
  panicSession   PanicSession @relation(fields: [panicSessionId], references: [id], onDelete: Cascade)
  wrappedKey     Bytes
  kmsKeyName     String
  kmsKeyVersion  String
  algorithm      String
  createdAt      DateTime @default(now())

  @@map("panic_session_keys")
}

// Bloque de audio cifrado subido a Storage — reemplaza recordingUrls (nunca poblado).
model RecordingBlock {
  id             String   @id @default(uuid())
  panicSessionId String
  panicSession   PanicSession @relation(fields: [panicSessionId], references: [id], onDelete: Cascade)
  blockIndex     Int
  storagePath    String        // gs://bucket/path — no URL pública
  uploadedAt     DateTime @default(now())

  @@unique([panicSessionId, blockIndex])
  @@map("recording_blocks")
}

// Bitácora inmutable de cada intento de recuperar la clave de una sesión.
model KeyAccessAudit {
  id             String   @id @default(uuid())
  panicSessionId String
  requestedById  String
  requestedAt    DateTime @default(now())
  ipAddress      String?
  result         String        // "SUCCESS" | "DENIED" | "ERROR"

  @@index([panicSessionId, requestedAt])
  @@map("key_access_audits")
}
```

- [ ] **Step 2: Validar el schema**

Run: `cd api && bun run prisma:validate`
Expected: `The schema at prisma/schema.prisma is valid 🚀`

- [ ] **Step 3: Generar la migración**

Run: `cd api && bunx prisma migrate dev --name add_panic_escrow_key`
Expected: crea `api/prisma/migrations/<timestamp>_add_panic_escrow_key/migration.sql` y aplica contra la DB local; termina con `Your database is now in sync with your schema.`

- [ ] **Step 4: Commit**

```bash
git add api/prisma/schema.prisma api/prisma/migrations
git commit -m "feat(api): agrega modelos de escrow de claves y bloques de grabación"
```

---

## Task 3: Repositorio de clave de escrow + usecase `storeEscrowKey`

**Files:**
- Create: `api/src/features/panic/domain/repositories/escrow-key.repository.ts`
- Create: `api/src/features/panic/infrastructure/prisma-escrow-key.repository.ts`
- Create: `api/src/features/panic/domain/usecases/store-escrow-key.usecase.ts`
- Test: `api/src/features/panic/__tests__/store-escrow-key.usecase.test.ts`

**Interfaces:**
- Consumes: `PanicSessionRepository.findById(id): Promise<PanicSession | null>` (ya existe en `panic-session.repository.ts`), `AppError` de `api/src/core/errors/AppError.ts`.
- Produces: `EscrowKeyRepository` (interfaz + impl Prisma), `storeEscrowKey(input, deps): Promise<void>` — usado por Task 6 (controller).

- [ ] **Step 1: Escribir el test que falla**

Crear `api/src/features/panic/__tests__/store-escrow-key.usecase.test.ts`:
```typescript
import { describe, it, expect, vi, beforeEach } from 'vitest';

import { storeEscrowKey } from '../domain/usecases/store-escrow-key.usecase';
import { AppError } from '../../../core/errors/AppError';

const mockPanicRepo = {
  findById: vi.fn(),
  create: vi.fn(),
  findActiveByUser: vi.fn(),
  findAllActive: vi.fn(),
  deactivate: vi.fn(),
  appendRecordingUrl: vi.fn(),
  addLocationPoint: vi.fn(),
};

const mockEscrowRepo = {
  create: vi.fn(),
  findBySessionId: vi.fn(),
};

const deps = {
  panicRepo: mockPanicRepo as any,
  escrowRepo: mockEscrowRepo as any,
  getUserId: vi.fn(),
};

const baseInput = {
  panicSessionId: 'ses-1',
  uid: 'firebase-uid-1',
  wrappedKey: Buffer.from('wrapped-bytes').toString('base64'),
  kmsKeyVersion: '1',
  algorithm: 'RSA_OAEP_256',
};

describe('storeEscrowKey', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('GIVEN sesión propia y sin clave previa WHEN se llama THEN crea el registro', async () => {
    mockPanicRepo.findById.mockResolvedValue({ id: 'ses-1', userId: 'user-1' });
    deps.getUserId.mockResolvedValue('user-1');
    mockEscrowRepo.findBySessionId.mockResolvedValue(null);

    await storeEscrowKey(baseInput, deps);

    expect(mockEscrowRepo.create).toHaveBeenCalledWith({
      panicSessionId: 'ses-1',
      wrappedKey: Buffer.from('wrapped-bytes'),
      kmsKeyVersion: '1',
      algorithm: 'RSA_OAEP_256',
    });
  });

  it('GIVEN sesión inexistente WHEN se llama THEN lanza 404', async () => {
    mockPanicRepo.findById.mockResolvedValue(null);
    deps.getUserId.mockResolvedValue('user-1');

    await expect(storeEscrowKey(baseInput, deps)).rejects.toThrow(AppError);
    expect(mockEscrowRepo.create).not.toHaveBeenCalled();
  });

  it('GIVEN sesión de otro usuario WHEN se llama THEN lanza 403', async () => {
    mockPanicRepo.findById.mockResolvedValue({ id: 'ses-1', userId: 'otro-user' });
    deps.getUserId.mockResolvedValue('user-1');

    await expect(storeEscrowKey(baseInput, deps)).rejects.toThrow(AppError);
    expect(mockEscrowRepo.create).not.toHaveBeenCalled();
  });

  it('GIVEN ya existe una clave para la sesión WHEN se llama THEN lanza 409', async () => {
    mockPanicRepo.findById.mockResolvedValue({ id: 'ses-1', userId: 'user-1' });
    deps.getUserId.mockResolvedValue('user-1');
    mockEscrowRepo.findBySessionId.mockResolvedValue({ wrappedKey: Buffer.from('x'), kmsKeyVersion: '1' });

    await expect(storeEscrowKey(baseInput, deps)).rejects.toThrow(AppError);
    expect(mockEscrowRepo.create).not.toHaveBeenCalled();
  });
});
```

- [ ] **Step 2: Correr el test y verificar que falla**

Run: `cd api && bun run test store-escrow-key.usecase.test.ts`
Expected: FAIL — `Cannot find module '../domain/usecases/store-escrow-key.usecase'`

- [ ] **Step 3: Implementar la interfaz del repositorio**

Crear `api/src/features/panic/domain/repositories/escrow-key.repository.ts`:
```typescript
export interface StoreEscrowKeyData {
  panicSessionId: string;
  wrappedKey: Buffer;
  kmsKeyVersion: string;
  algorithm: string;
}

export interface StoredEscrowKey {
  wrappedKey: Buffer;
  kmsKeyVersion: string;
}

export interface EscrowKeyRepository {
  create(data: StoreEscrowKeyData): Promise<void>;
  findBySessionId(panicSessionId: string): Promise<StoredEscrowKey | null>;
}
```

- [ ] **Step 4: Implementar la impl Prisma**

Crear `api/src/features/panic/infrastructure/prisma-escrow-key.repository.ts`:
```typescript
import { PrismaClient } from '@prisma/client';

import {
  EscrowKeyRepository,
  StoreEscrowKeyData,
  StoredEscrowKey,
} from '../domain/repositories/escrow-key.repository';
import { env } from '../../../core/config/env';

export class PrismaEscrowKeyRepository implements EscrowKeyRepository {
  constructor(private readonly prisma: PrismaClient) {}

  async create(data: StoreEscrowKeyData): Promise<void> {
    await this.prisma.panicSessionKey.create({
      data: {
        panicSessionId: data.panicSessionId,
        wrappedKey: data.wrappedKey,
        kmsKeyName: `projects/${env.KMS_PROJECT_ID}/locations/${env.KMS_LOCATION_ID}/keyRings/${env.KMS_KEY_RING_ID}/cryptoKeys/${env.KMS_KEY_ID}`,
        kmsKeyVersion: data.kmsKeyVersion,
        algorithm: data.algorithm,
      },
    });
  }

  async findBySessionId(panicSessionId: string): Promise<StoredEscrowKey | null> {
    const row = await this.prisma.panicSessionKey.findUnique({ where: { panicSessionId } });
    if (!row) return null;
    return { wrappedKey: Buffer.from(row.wrappedKey), kmsKeyVersion: row.kmsKeyVersion };
  }
}
```

- [ ] **Step 5: Implementar el usecase**

Crear `api/src/features/panic/domain/usecases/store-escrow-key.usecase.ts`:
```typescript
import { PanicSessionRepository } from '../repositories/panic-session.repository';
import { EscrowKeyRepository } from '../repositories/escrow-key.repository';
import { AppError } from '../../../../core/errors/AppError';

export interface StoreEscrowKeyInput {
  panicSessionId: string;
  uid: string;
  wrappedKey: string; // base64
  kmsKeyVersion: string;
  algorithm: string;
}

export interface StoreEscrowKeyDeps {
  panicRepo: PanicSessionRepository;
  escrowRepo: EscrowKeyRepository;
  getUserId: (uid: string) => Promise<string>;
}

export async function storeEscrowKey(
  input: StoreEscrowKeyInput,
  deps: StoreEscrowKeyDeps,
): Promise<void> {
  const session = await deps.panicRepo.findById(input.panicSessionId);
  if (!session) {
    throw new AppError(404, 'Sesión de pánico no encontrada');
  }

  const userId = await deps.getUserId(input.uid);
  if (session.userId !== userId) {
    throw new AppError(403, 'No autorizado para esta sesión');
  }

  const existing = await deps.escrowRepo.findBySessionId(input.panicSessionId);
  if (existing) {
    throw new AppError(409, 'Ya existe una clave de escrow para esta sesión');
  }

  await deps.escrowRepo.create({
    panicSessionId: input.panicSessionId,
    wrappedKey: Buffer.from(input.wrappedKey, 'base64'),
    kmsKeyVersion: input.kmsKeyVersion,
    algorithm: input.algorithm,
  });
}
```

- [ ] **Step 6: Correr el test y verificar que pasa**

Run: `cd api && bun run test store-escrow-key.usecase.test.ts`
Expected: PASS (4 tests)

- [ ] **Step 7: Commit**

```bash
git add api/src/features/panic/domain/repositories/escrow-key.repository.ts \
        api/src/features/panic/infrastructure/prisma-escrow-key.repository.ts \
        api/src/features/panic/domain/usecases/store-escrow-key.usecase.ts \
        api/src/features/panic/__tests__/store-escrow-key.usecase.test.ts
git commit -m "feat(api): agrega repo y usecase para almacenar la clave de escrow"
```

---

## Task 4: Repositorio de bloques + usecase `registerRecordingBlock`

**Files:**
- Create: `api/src/features/panic/domain/repositories/recording-block.repository.ts`
- Create: `api/src/features/panic/infrastructure/prisma-recording-block.repository.ts`
- Create: `api/src/features/panic/domain/usecases/register-recording-block.usecase.ts`
- Test: `api/src/features/panic/__tests__/register-recording-block.usecase.test.ts`

**Interfaces:**
- Consumes: `PanicSessionRepository.findById` (Task existente), `AppError`.
- Produces: `RecordingBlockRepository` (interfaz + impl), `registerRecordingBlock(input, deps): Promise<void>` — usado por Task 6. `RecordingBlockRepository.findBySessionId` también lo consume Task 5.

- [ ] **Step 1: Escribir el test que falla**

Crear `api/src/features/panic/__tests__/register-recording-block.usecase.test.ts`:
```typescript
import { describe, it, expect, vi, beforeEach } from 'vitest';

import { registerRecordingBlock } from '../domain/usecases/register-recording-block.usecase';
import { AppError } from '../../../core/errors/AppError';

const mockPanicRepo = {
  findById: vi.fn(),
  create: vi.fn(),
  findActiveByUser: vi.fn(),
  findAllActive: vi.fn(),
  deactivate: vi.fn(),
  appendRecordingUrl: vi.fn(),
  addLocationPoint: vi.fn(),
};

const mockBlockRepo = {
  upsert: vi.fn(),
  findBySessionId: vi.fn(),
};

const deps = {
  panicRepo: mockPanicRepo as any,
  blockRepo: mockBlockRepo as any,
  getUserId: vi.fn(),
};

const baseInput = {
  panicSessionId: 'ses-1',
  uid: 'firebase-uid-1',
  blockIndex: 2,
  storagePath: 'gs://alertaya-bucket/panic/ses-1/audio/block_2.bin',
};

describe('registerRecordingBlock', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('GIVEN sesión propia WHEN se llama THEN hace upsert del bloque', async () => {
    mockPanicRepo.findById.mockResolvedValue({ id: 'ses-1', userId: 'user-1' });
    deps.getUserId.mockResolvedValue('user-1');

    await registerRecordingBlock(baseInput, deps);

    expect(mockBlockRepo.upsert).toHaveBeenCalledWith({
      panicSessionId: 'ses-1',
      blockIndex: 2,
      storagePath: baseInput.storagePath,
    });
  });

  it('GIVEN sesión inexistente WHEN se llama THEN lanza 404', async () => {
    mockPanicRepo.findById.mockResolvedValue(null);
    deps.getUserId.mockResolvedValue('user-1');

    await expect(registerRecordingBlock(baseInput, deps)).rejects.toThrow(AppError);
    expect(mockBlockRepo.upsert).not.toHaveBeenCalled();
  });

  it('GIVEN sesión de otro usuario WHEN se llama THEN lanza 403', async () => {
    mockPanicRepo.findById.mockResolvedValue({ id: 'ses-1', userId: 'otro-user' });
    deps.getUserId.mockResolvedValue('user-1');

    await expect(registerRecordingBlock(baseInput, deps)).rejects.toThrow(AppError);
    expect(mockBlockRepo.upsert).not.toHaveBeenCalled();
  });
});
```

- [ ] **Step 2: Correr el test y verificar que falla**

Run: `cd api && bun run test register-recording-block.usecase.test.ts`
Expected: FAIL — módulo no encontrado

- [ ] **Step 3: Implementar la interfaz del repositorio**

Crear `api/src/features/panic/domain/repositories/recording-block.repository.ts`:
```typescript
export interface RecordingBlockData {
  panicSessionId: string;
  blockIndex: number;
  storagePath: string;
}

export interface StoredRecordingBlock {
  blockIndex: number;
  storagePath: string;
}

export interface RecordingBlockRepository {
  upsert(data: RecordingBlockData): Promise<void>;
  findBySessionId(panicSessionId: string): Promise<StoredRecordingBlock[]>;
}
```

- [ ] **Step 4: Implementar la impl Prisma**

Crear `api/src/features/panic/infrastructure/prisma-recording-block.repository.ts`:
```typescript
import { PrismaClient } from '@prisma/client';

import {
  RecordingBlockRepository,
  RecordingBlockData,
  StoredRecordingBlock,
} from '../domain/repositories/recording-block.repository';

export class PrismaRecordingBlockRepository implements RecordingBlockRepository {
  constructor(private readonly prisma: PrismaClient) {}

  async upsert(data: RecordingBlockData): Promise<void> {
    await this.prisma.recordingBlock.upsert({
      where: {
        panicSessionId_blockIndex: {
          panicSessionId: data.panicSessionId,
          blockIndex: data.blockIndex,
        },
      },
      create: {
        panicSessionId: data.panicSessionId,
        blockIndex: data.blockIndex,
        storagePath: data.storagePath,
      },
      update: {
        storagePath: data.storagePath,
      },
    });
  }

  async findBySessionId(panicSessionId: string): Promise<StoredRecordingBlock[]> {
    const rows = await this.prisma.recordingBlock.findMany({
      where: { panicSessionId },
      orderBy: { blockIndex: 'asc' },
    });
    return rows.map((r) => ({ blockIndex: r.blockIndex, storagePath: r.storagePath }));
  }
}
```

- [ ] **Step 5: Implementar el usecase**

Crear `api/src/features/panic/domain/usecases/register-recording-block.usecase.ts`:
```typescript
import { PanicSessionRepository } from '../repositories/panic-session.repository';
import { RecordingBlockRepository } from '../repositories/recording-block.repository';
import { AppError } from '../../../../core/errors/AppError';

export interface RegisterRecordingBlockInput {
  panicSessionId: string;
  uid: string;
  blockIndex: number;
  storagePath: string;
}

export interface RegisterRecordingBlockDeps {
  panicRepo: PanicSessionRepository;
  blockRepo: RecordingBlockRepository;
  getUserId: (uid: string) => Promise<string>;
}

export async function registerRecordingBlock(
  input: RegisterRecordingBlockInput,
  deps: RegisterRecordingBlockDeps,
): Promise<void> {
  const session = await deps.panicRepo.findById(input.panicSessionId);
  if (!session) {
    throw new AppError(404, 'Sesión de pánico no encontrada');
  }

  const userId = await deps.getUserId(input.uid);
  if (session.userId !== userId) {
    throw new AppError(403, 'No autorizado para esta sesión');
  }

  await deps.blockRepo.upsert({
    panicSessionId: input.panicSessionId,
    blockIndex: input.blockIndex,
    storagePath: input.storagePath,
  });
}
```

- [ ] **Step 6: Correr el test y verificar que pasa**

Run: `cd api && bun run test register-recording-block.usecase.test.ts`
Expected: PASS (3 tests)

- [ ] **Step 7: Commit**

```bash
git add api/src/features/panic/domain/repositories/recording-block.repository.ts \
        api/src/features/panic/infrastructure/prisma-recording-block.repository.ts \
        api/src/features/panic/domain/usecases/register-recording-block.usecase.ts \
        api/src/features/panic/__tests__/register-recording-block.usecase.test.ts
git commit -m "feat(api): agrega repo y usecase para registrar bloques de grabación"
```

---

## Task 5: Auditoría + usecase `releaseRecordingKey`

**Files:**
- Create: `api/src/features/panic/domain/repositories/key-access-audit.repository.ts`
- Create: `api/src/features/panic/infrastructure/prisma-key-access-audit.repository.ts`
- Create: `api/src/features/panic/domain/usecases/release-recording-key.usecase.ts`
- Test: `api/src/features/panic/__tests__/release-recording-key.usecase.test.ts`

**Interfaces:**
- Consumes: `EscrowKeyRepository.findBySessionId` (Task 3), `RecordingBlockRepository.findBySessionId` (Task 4), `unwrapEscrowKey(wrappedKey: Buffer, keyVersion: string): Promise<Buffer>` (Task 1), `getSignedUrl(gsPath: string): Promise<string | null>` (existente en `api/src/core/config/firebase.ts`).
- Produces: `releaseRecordingKey(input, deps): Promise<ReleaseRecordingKeyResult>` con `ReleaseRecordingKeyResult = { aesKey: string; blocks: { index: number; url: string }[] }` — usado por Task 6.

- [ ] **Step 1: Escribir el test que falla**

Crear `api/src/features/panic/__tests__/release-recording-key.usecase.test.ts`:
```typescript
import { describe, it, expect, vi, beforeEach } from 'vitest';

import { releaseRecordingKey } from '../domain/usecases/release-recording-key.usecase';
import { AppError } from '../../../core/errors/AppError';

const mockEscrowRepo = { create: vi.fn(), findBySessionId: vi.fn() };
const mockBlockRepo = { upsert: vi.fn(), findBySessionId: vi.fn() };
const mockAuditRepo = { create: vi.fn() };
const unwrapKey = vi.fn();
const getSignedUrl = vi.fn();

const deps = {
  escrowRepo: mockEscrowRepo as any,
  blockRepo: mockBlockRepo as any,
  auditRepo: mockAuditRepo as any,
  unwrapKey,
  getSignedUrl,
};

const baseInput = {
  panicSessionId: 'ses-1',
  requestedById: 'authority-1',
  ipAddress: '10.0.0.1',
};

describe('releaseRecordingKey', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('GIVEN escrow y bloques existentes WHEN se llama THEN devuelve la clave y las URLs, y audita SUCCESS', async () => {
    mockEscrowRepo.findBySessionId.mockResolvedValue({
      wrappedKey: Buffer.from('wrapped'),
      kmsKeyVersion: '1',
    });
    mockBlockRepo.findBySessionId.mockResolvedValue([
      { blockIndex: 0, storagePath: 'gs://bucket/block_0.bin' },
      { blockIndex: 1, storagePath: 'gs://bucket/block_1.bin' },
    ]);
    unwrapKey.mockResolvedValue(Buffer.from('clave-aes'));
    getSignedUrl.mockImplementation(async (path: string) => `https://signed/${path}`);

    const result = await releaseRecordingKey(baseInput, deps);

    expect(result.aesKey).toBe(Buffer.from('clave-aes').toString('base64'));
    expect(result.blocks).toEqual([
      { index: 0, url: 'https://signed/gs://bucket/block_0.bin' },
      { index: 1, url: 'https://signed/gs://bucket/block_1.bin' },
    ]);
    expect(mockAuditRepo.create).toHaveBeenCalledWith({
      panicSessionId: 'ses-1',
      requestedById: 'authority-1',
      ipAddress: '10.0.0.1',
      result: 'SUCCESS',
    });
  });

  it('GIVEN sin clave de escrow WHEN se llama THEN lanza 404 y audita ERROR', async () => {
    mockEscrowRepo.findBySessionId.mockResolvedValue(null);

    await expect(releaseRecordingKey(baseInput, deps)).rejects.toThrow(AppError);
    expect(mockAuditRepo.create).toHaveBeenCalledWith({
      panicSessionId: 'ses-1',
      requestedById: 'authority-1',
      ipAddress: '10.0.0.1',
      result: 'ERROR',
    });
  });

  it('GIVEN bloques sin URL firmable WHEN se llama THEN los omite del resultado', async () => {
    mockEscrowRepo.findBySessionId.mockResolvedValue({
      wrappedKey: Buffer.from('wrapped'),
      kmsKeyVersion: '1',
    });
    mockBlockRepo.findBySessionId.mockResolvedValue([
      { blockIndex: 0, storagePath: 'gs://bucket/block_0.bin' },
    ]);
    unwrapKey.mockResolvedValue(Buffer.from('clave-aes'));
    getSignedUrl.mockResolvedValue(null);

    const result = await releaseRecordingKey(baseInput, deps);

    expect(result.blocks).toEqual([]);
  });
});
```

- [ ] **Step 2: Correr el test y verificar que falla**

Run: `cd api && bun run test release-recording-key.usecase.test.ts`
Expected: FAIL — módulo no encontrado

- [ ] **Step 3: Implementar la interfaz y la impl del repo de auditoría**

Crear `api/src/features/panic/domain/repositories/key-access-audit.repository.ts`:
```typescript
export type KeyAccessResult = 'SUCCESS' | 'DENIED' | 'ERROR';

export interface KeyAccessAuditData {
  panicSessionId: string;
  requestedById: string;
  ipAddress: string | null;
  result: KeyAccessResult;
}

export interface KeyAccessAuditRepository {
  create(data: KeyAccessAuditData): Promise<void>;
}
```

Crear `api/src/features/panic/infrastructure/prisma-key-access-audit.repository.ts`:
```typescript
import { PrismaClient } from '@prisma/client';

import { KeyAccessAuditRepository, KeyAccessAuditData } from '../domain/repositories/key-access-audit.repository';

export class PrismaKeyAccessAuditRepository implements KeyAccessAuditRepository {
  constructor(private readonly prisma: PrismaClient) {}

  async create(data: KeyAccessAuditData): Promise<void> {
    await this.prisma.keyAccessAudit.create({
      data: {
        panicSessionId: data.panicSessionId,
        requestedById: data.requestedById,
        ipAddress: data.ipAddress,
        result: data.result,
      },
    });
  }
}
```

- [ ] **Step 4: Implementar el usecase**

Crear `api/src/features/panic/domain/usecases/release-recording-key.usecase.ts`:
```typescript
import { EscrowKeyRepository } from '../repositories/escrow-key.repository';
import { RecordingBlockRepository } from '../repositories/recording-block.repository';
import { KeyAccessAuditRepository } from '../repositories/key-access-audit.repository';
import { AppError } from '../../../../core/errors/AppError';

export interface ReleaseRecordingKeyInput {
  panicSessionId: string;
  requestedById: string;
  ipAddress: string | null;
}

export interface ReleaseRecordingKeyDeps {
  escrowRepo: EscrowKeyRepository;
  blockRepo: RecordingBlockRepository;
  auditRepo: KeyAccessAuditRepository;
  unwrapKey: (wrappedKey: Buffer, keyVersion: string) => Promise<Buffer>;
  getSignedUrl: (storagePath: string) => Promise<string | null>;
}

export interface ReleasedBlock {
  index: number;
  url: string;
}

export interface ReleaseRecordingKeyResult {
  aesKey: string; // base64
  blocks: ReleasedBlock[];
}

export async function releaseRecordingKey(
  input: ReleaseRecordingKeyInput,
  deps: ReleaseRecordingKeyDeps,
): Promise<ReleaseRecordingKeyResult> {
  try {
    const escrow = await deps.escrowRepo.findBySessionId(input.panicSessionId);
    if (!escrow) {
      throw new AppError(404, 'No hay clave de escrow para esta sesión');
    }

    const aesKeyBuffer = await deps.unwrapKey(escrow.wrappedKey, escrow.kmsKeyVersion);
    const storedBlocks = await deps.blockRepo.findBySessionId(input.panicSessionId);

    const blocks: ReleasedBlock[] = [];
    for (const block of storedBlocks) {
      const url = await deps.getSignedUrl(block.storagePath);
      if (url) {
        blocks.push({ index: block.blockIndex, url });
      }
    }

    await deps.auditRepo.create({
      panicSessionId: input.panicSessionId,
      requestedById: input.requestedById,
      ipAddress: input.ipAddress,
      result: 'SUCCESS',
    });

    return { aesKey: aesKeyBuffer.toString('base64'), blocks };
  } catch (err) {
    await deps.auditRepo.create({
      panicSessionId: input.panicSessionId,
      requestedById: input.requestedById,
      ipAddress: input.ipAddress,
      result: 'ERROR',
    });
    throw err;
  }
}
```

- [ ] **Step 5: Correr el test y verificar que pasa**

Run: `cd api && bun run test release-recording-key.usecase.test.ts`
Expected: PASS (3 tests)

- [ ] **Step 6: Commit**

```bash
git add api/src/features/panic/domain/repositories/key-access-audit.repository.ts \
        api/src/features/panic/infrastructure/prisma-key-access-audit.repository.ts \
        api/src/features/panic/domain/usecases/release-recording-key.usecase.ts \
        api/src/features/panic/__tests__/release-recording-key.usecase.test.ts
git commit -m "feat(api): agrega auditoría y usecase para liberar la clave de una sesión"
```

---

## Task 6: Endpoints — schemas, controller, router

**Files:**
- Modify: `api/src/features/panic/presentation/panic.schema.ts`
- Modify: `api/src/features/panic/presentation/panic.controller.ts`
- Modify: `api/src/features/panic/presentation/panic.router.ts`
- Test: `api/src/features/panic/presentation/__tests__/panic-escrow.controller.test.ts`

**Interfaces:**
- Consumes: `getEscrowPublicKey`, `unwrapEscrowKey` (Task 1); `storeEscrowKey` (Task 3); `registerRecordingBlock` (Task 4); `releaseRecordingKey` (Task 5); `getSignedUrl` (existente en `api/src/core/config/firebase.ts`); `authorityMiddleware` (existente).
- Produces: endpoints `GET /panic/escrow/public-key`, `POST /panic/sessions/:id/escrow-key`, `POST /panic/sessions/:id/blocks`, `POST /panic/sessions/:id/recordings/access` — contrato que consumirá la web de autoridades (fuera de alcance de este plan).

- [ ] **Step 1: Agregar los schemas zod**

En `api/src/features/panic/presentation/panic.schema.ts`, agregar al final del archivo:
```typescript
export const escrowKeySchema = z.object({
  wrappedKey: z.string().min(1),
  kmsKeyVersion: z.string().min(1),
  algorithm: z.literal('RSA_OAEP_256'),
});

export const registerBlockSchema = z.object({
  blockIndex: z.number().int().min(0),
  storagePath: z.string().startsWith('gs://'),
});
```

- [ ] **Step 2: Escribir el test de controller que falla**

Crear `api/src/features/panic/presentation/__tests__/panic-escrow.controller.test.ts`:
```typescript
import { describe, it, expect, vi } from 'vitest';
import request from 'supertest';
import express from 'express';

import { errorHandlerMiddleware } from '../../../../core/middleware/errorHandler.middleware';

vi.mock('../../../../core/config/prisma', () => ({ prisma: {}, disconnectPrisma: vi.fn() }));

vi.mock('firebase-admin/auth', () => ({
  getAuth: vi.fn(() => ({
    verifyIdToken: vi.fn().mockImplementation(async (token: string) => {
      if (token === 'authority-token') return { uid: 'authority-uid', role: 'AUTHORITY' };
      return { uid: 'citizen-uid' };
    }),
  })),
}));

vi.mock('../../infrastructure/prisma-panic.repository', () => ({
  PrismaPanicRepository: vi.fn().mockImplementation(() => ({
    findById: vi.fn().mockResolvedValue({ id: 'ses-1', userId: 'user-id' }),
  })),
}));
vi.mock('../../infrastructure/prisma-escrow-key.repository', () => ({
  PrismaEscrowKeyRepository: vi.fn().mockImplementation(() => ({})),
}));
vi.mock('../../infrastructure/prisma-recording-block.repository', () => ({
  PrismaRecordingBlockRepository: vi.fn().mockImplementation(() => ({})),
}));
vi.mock('../../infrastructure/prisma-key-access-audit.repository', () => ({
  PrismaKeyAccessAuditRepository: vi.fn().mockImplementation(() => ({})),
}));
vi.mock('../../../incidents/infrastructure/user-lookup.service', () => ({
  UserLookupService: vi.fn().mockImplementation(() => ({
    findOrCreate: vi.fn().mockResolvedValue({ id: 'user-id' }),
  })),
}));
vi.mock('../../../../core/config/kms', () => ({
  getEscrowPublicKey: vi.fn().mockResolvedValue({ publicKeyPem: 'PEM', keyVersion: '1' }),
  unwrapEscrowKey: vi.fn(),
}));
vi.mock('../../../../core/config/firebase', () => ({
  getSignedUrl: vi.fn().mockResolvedValue('https://signed-url'),
}));
vi.mock('../../domain/usecases/store-escrow-key.usecase', () => ({
  storeEscrowKey: vi.fn().mockResolvedValue(undefined),
}));
vi.mock('../../domain/usecases/register-recording-block.usecase', () => ({
  registerRecordingBlock: vi.fn().mockResolvedValue(undefined),
}));
vi.mock('../../domain/usecases/release-recording-key.usecase', () => ({
  releaseRecordingKey: vi.fn().mockResolvedValue({ aesKey: 'base64key', blocks: [] }),
}));

const { panicRouter } = await import('../panic.router');

const app = express();
app.use(express.json());
app.use('/panic', panicRouter);
app.use(errorHandlerMiddleware);

describe('GET /panic/escrow/public-key', () => {
  it('devuelve la pública KMS con token válido', async () => {
    const res = await request(app)
      .get('/panic/escrow/public-key')
      .set('Authorization', 'Bearer citizen-token');

    expect(res.status).toBe(200);
    expect(res.body).toEqual({ publicKeyPem: 'PEM', kmsKeyVersion: '1' });
  });

  it('rechaza sin token', async () => {
    const res = await request(app).get('/panic/escrow/public-key');
    expect(res.status).toBe(401);
  });
});

describe('POST /panic/sessions/:id/escrow-key', () => {
  it('acepta un wrapped key válido', async () => {
    const res = await request(app)
      .post('/panic/sessions/ses-1/escrow-key')
      .set('Authorization', 'Bearer citizen-token')
      .send({ wrappedKey: 'd2FubmVk', kmsKeyVersion: '1', algorithm: 'RSA_OAEP_256' });

    expect(res.status).toBe(201);
  });

  it('rechaza body inválido (algorithm incorrecto)', async () => {
    const res = await request(app)
      .post('/panic/sessions/ses-1/escrow-key')
      .set('Authorization', 'Bearer citizen-token')
      .send({ wrappedKey: 'd2FubmVk', kmsKeyVersion: '1', algorithm: 'AES' });

    expect(res.status).toBe(400);
  });
});

describe('POST /panic/sessions/:id/blocks', () => {
  it('registra un bloque válido', async () => {
    const res = await request(app)
      .post('/panic/sessions/ses-1/blocks')
      .set('Authorization', 'Bearer citizen-token')
      .send({ blockIndex: 0, storagePath: 'gs://bucket/block_0.bin' });

    expect(res.status).toBe(201);
  });

  it('rechaza storagePath sin prefijo gs://', async () => {
    const res = await request(app)
      .post('/panic/sessions/ses-1/blocks')
      .set('Authorization', 'Bearer citizen-token')
      .send({ blockIndex: 0, storagePath: 'https://bucket/block_0.bin' });

    expect(res.status).toBe(400);
  });
});

describe('POST /panic/sessions/:id/recordings/access', () => {
  it('permite acceso a una autoridad', async () => {
    const res = await request(app)
      .post('/panic/sessions/ses-1/recordings/access')
      .set('Authorization', 'Bearer authority-token');

    expect(res.status).toBe(200);
    expect(res.body).toEqual({ aesKey: 'base64key', blocks: [] });
  });

  it('rechaza a un ciudadano sin rol de autoridad', async () => {
    const res = await request(app)
      .post('/panic/sessions/ses-1/recordings/access')
      .set('Authorization', 'Bearer citizen-token');

    expect(res.status).toBe(403);
  });
});
```

- [ ] **Step 3: Correr el test y verificar que falla**

Run: `cd api && bun run test panic-escrow.controller.test.ts`
Expected: FAIL — las rutas no existen (404) o los handlers no están exportados

- [ ] **Step 4: Agregar los handlers al controller**

En `api/src/features/panic/presentation/panic.controller.ts`, agregar los imports necesarios junto a los existentes:
```typescript
import { PrismaEscrowKeyRepository } from '../infrastructure/prisma-escrow-key.repository';
import { PrismaRecordingBlockRepository } from '../infrastructure/prisma-recording-block.repository';
import { PrismaKeyAccessAuditRepository } from '../infrastructure/prisma-key-access-audit.repository';
import { getEscrowPublicKey, unwrapEscrowKey } from '../../../core/config/kms';
import { getSignedUrl } from '../../../core/config/firebase';
import { storeEscrowKey } from '../domain/usecases/store-escrow-key.usecase';
import { registerRecordingBlock } from '../domain/usecases/register-recording-block.usecase';
import { releaseRecordingKey } from '../domain/usecases/release-recording-key.usecase';
```

Agregar junto a las instancias de `panicRepo`/`userLookup` a nivel de módulo:
```typescript
const escrowKeyRepo = new PrismaEscrowKeyRepository(prisma);
const recordingBlockRepo = new PrismaRecordingBlockRepository(prisma);
const keyAccessAuditRepo = new PrismaKeyAccessAuditRepository(prisma);
```

Agregar los handlers al final del archivo:
```typescript
export async function getEscrowPublicKeyHandler(
  _req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> {
  try {
    const { publicKeyPem, keyVersion } = await getEscrowPublicKey();
    res.json({ publicKeyPem, kmsKeyVersion: keyVersion });
  } catch (err) {
    next(err);
  }
}

export async function submitEscrowKeyHandler(
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> {
  try {
    if (!req.user?.uid) {
      next(new AppError(401, 'No autenticado'));
      return;
    }
    const body = req.body as { wrappedKey: string; kmsKeyVersion: string; algorithm: string };
    await storeEscrowKey(
      { panicSessionId: req.params['id']!, uid: req.user.uid, ...body },
      {
        panicRepo,
        escrowRepo: escrowKeyRepo,
        getUserId: async (uid) => (await userLookup.findOrCreate(uid)).id,
      },
    );
    res.status(201).end();
  } catch (err) {
    next(err);
  }
}

export async function registerBlockHandler(
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> {
  try {
    if (!req.user?.uid) {
      next(new AppError(401, 'No autenticado'));
      return;
    }
    const body = req.body as { blockIndex: number; storagePath: string };
    await registerRecordingBlock(
      { panicSessionId: req.params['id']!, uid: req.user.uid, ...body },
      {
        panicRepo,
        blockRepo: recordingBlockRepo,
        getUserId: async (uid) => (await userLookup.findOrCreate(uid)).id,
      },
    );
    res.status(201).end();
  } catch (err) {
    next(err);
  }
}

export async function releaseRecordingKeyHandler(
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> {
  try {
    if (!req.user?.uid) {
      next(new AppError(401, 'No autenticado'));
      return;
    }
    const requester = await userLookup.findOrCreate(req.user.uid);
    const result = await releaseRecordingKey(
      {
        panicSessionId: req.params['id']!,
        requestedById: requester.id,
        ipAddress: req.ip ?? null,
      },
      {
        escrowRepo: escrowKeyRepo,
        blockRepo: recordingBlockRepo,
        auditRepo: keyAccessAuditRepo,
        unwrapKey: unwrapEscrowKey,
        getSignedUrl,
      },
    );
    res.json(result);
  } catch (err) {
    next(err);
  }
}
```

- [ ] **Step 5: Registrar las rutas**

En `api/src/features/panic/presentation/panic.router.ts`, agregar el import de los nuevos schemas/handlers y las rutas:
```typescript
import { escrowKeySchema, registerBlockSchema } from './panic.schema';
import {
  getEscrowPublicKeyHandler,
  submitEscrowKeyHandler,
  registerBlockHandler,
  releaseRecordingKeyHandler,
} from './panic.controller';
import { authorityMiddleware } from '../../../core/middleware/authority.middleware';
```

Agregar al final de la definición de rutas, antes de `export { router as panicRouter };`:
```typescript
router.get('/escrow/public-key', authMiddleware, getEscrowPublicKeyHandler);
router.post(
  '/sessions/:id/escrow-key',
  authMiddleware,
  validate(stopPanicParamsSchema, 'params'),
  validate(escrowKeySchema),
  submitEscrowKeyHandler,
);
router.post(
  '/sessions/:id/blocks',
  authMiddleware,
  validate(stopPanicParamsSchema, 'params'),
  validate(registerBlockSchema),
  registerBlockHandler,
);
router.post(
  '/sessions/:id/recordings/access',
  authMiddleware,
  authorityMiddleware,
  validate(stopPanicParamsSchema, 'params'),
  releaseRecordingKeyHandler,
);
```

- [ ] **Step 6: Correr el test y verificar que pasa**

Run: `cd api && bun run test panic-escrow.controller.test.ts`
Expected: PASS (9 tests)

- [ ] **Step 7: Correr toda la suite del feature panic para evitar regresiones**

Run: `cd api && bun run test panic`
Expected: PASS (todos los tests de `features/panic`)

- [ ] **Step 8: Commit**

```bash
git add api/src/features/panic/presentation
git commit -m "feat(api): expone endpoints de escrow, registro de bloques y acceso a claves"
```

---

## Task 7: Mobile — migrar cifrado a AES-256-GCM y agregar wrap RSA-OAEP

**Files:**
- Modify: `mobile/lib/core/utils/encryption_util.dart`
- Modify: `mobile/pubspec.yaml`
- Test: `mobile/test/core/utils/encryption_util_test.dart`

**Interfaces:**
- Produces: `EncryptionUtil.generateKey(): Uint8List`, `EncryptionUtil.encrypt(Uint8List, Uint8List): Uint8List`, `EncryptionUtil.decrypt(Uint8List, Uint8List): Uint8List`, `EncryptionUtil.wrapKeyRsaOaep(Uint8List aesKey, String publicKeyPem): Uint8List` — usados por Task 9.

- [ ] **Step 1: Agregar dependencias**

Run: `cd mobile && flutter pub add pointycastle basic_utils`

- [ ] **Step 2: Escribir el test que falla**

Crear `mobile/test/core/utils/encryption_util_test.dart`:
```dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:alertaya/core/utils/encryption_util.dart';

// Clave pública RSA-2048 de prueba (no sensible, solo para tests).
const _testPublicKeyPem = '''
-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA7P7cLcLhbz4BEQGfDSz+
Xr3ZXrhBksBwzbVGU9mOrgTvT0OtLpfzOI6+ZzWd/SCmnj3CTcX3ODfWHXwjLryk
d4kjFVOON4YSAT52vbwDvHPFkV8cHYoOcsEeljd+41Hwbr2f1VyZdQAXZLFU8qMq
ZbzYYOYPkljyDoPU4PGjWnLT4L5WL/Cm8qyqcEb4hN/OQ9b/6ZUaHz5zfsYV1hBX
lMoIm/s5UphYiygXhEmSnPxhZa0Qm9lzilsnnYry1PLiPMrWnXQXJzqxr+3DOhqD
zGqOHKIBbxMt5/ysxbUP1vwX+4GxnVHL+1p/rDl2PY00W6NfWfMDfbRQZSAA30bs
TwIDAQAB
-----END PUBLIC KEY-----
''';

void main() {
  group('EncryptionUtil — AES-256-GCM', () {
    test('generateKey produce 32 bytes distintos en cada llamada', () {
      final k1 = EncryptionUtil.generateKey();
      final k2 = EncryptionUtil.generateKey();

      expect(k1.length, 32);
      expect(k1, isNot(equals(k2)));
    });

    test('encrypt + decrypt hace roundtrip del plaintext original', () {
      final key = EncryptionUtil.generateKey();
      final plaintext = Uint8List.fromList(utf8.encode('audio de prueba'));

      final blob = EncryptionUtil.encrypt(plaintext, key);
      final decrypted = EncryptionUtil.decrypt(blob, key);

      expect(utf8.decode(decrypted), 'audio de prueba');
    });

    test('el blob cifrado tiene el formato IV(12) || ciphertext || tag(16)', () {
      final key = EncryptionUtil.generateKey();
      final plaintext = Uint8List.fromList(utf8.encode('x'));

      final blob = EncryptionUtil.encrypt(plaintext, key);

      // 12 (IV) + 1 (ciphertext de 1 byte) + 16 (tag) = 29
      expect(blob.length, 29);
    });

    test('decrypt lanza si el blob fue alterado (autenticación GCM)', () {
      final key = EncryptionUtil.generateKey();
      final plaintext = Uint8List.fromList(utf8.encode('audio de prueba'));
      final blob = EncryptionUtil.encrypt(plaintext, key);

      final tampered = Uint8List.fromList(blob);
      tampered[tampered.length - 1] ^= 0xFF; // corrompe el último byte del tag

      expect(() => EncryptionUtil.decrypt(tampered, key), throwsA(anything));
    });

    test('decrypt lanza con la clave equivocada', () {
      final key = EncryptionUtil.generateKey();
      final otherKey = EncryptionUtil.generateKey();
      final plaintext = Uint8List.fromList(utf8.encode('audio de prueba'));
      final blob = EncryptionUtil.encrypt(plaintext, key);

      expect(() => EncryptionUtil.decrypt(blob, otherKey), throwsA(anything));
    });
  });

  group('EncryptionUtil — wrapKeyRsaOaep', () {
    test('devuelve 256 bytes (RSA-2048) distintos del plaintext', () {
      final aesKey = EncryptionUtil.generateKey();

      final wrapped = EncryptionUtil.wrapKeyRsaOaep(aesKey, _testPublicKeyPem);

      expect(wrapped.length, 256);
      expect(wrapped, isNot(equals(aesKey)));
    });

    test('dos llamadas con la misma clave producen ciphertexts distintos (OAEP es probabilístico)', () {
      final aesKey = EncryptionUtil.generateKey();

      final wrapped1 = EncryptionUtil.wrapKeyRsaOaep(aesKey, _testPublicKeyPem);
      final wrapped2 = EncryptionUtil.wrapKeyRsaOaep(aesKey, _testPublicKeyPem);

      expect(wrapped1, isNot(equals(wrapped2)));
    });
  });
}
```

- [ ] **Step 3: Correr el test y verificar que falla**

Run: `cd mobile && flutter test test/core/utils/encryption_util_test.dart`
Expected: FAIL — `decrypt`/`wrapKeyRsaOaep` no existen aún, y el modo sigue siendo CBC

- [ ] **Step 4: Reescribir `encryption_util.dart`**

Reemplazar el contenido completo de `mobile/lib/core/utils/encryption_util.dart`:
```dart
import 'dart:typed_data';

import 'package:basic_utils/basic_utils.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:pointycastle/export.dart' as pc;

/// AES-256-GCM para cifrar grabaciones del pánico antes de subir a Storage.
/// Formato del blob: IV(12) || ciphertext || tag(16) — GCM autentica el
/// contenido: un blob alterado o una clave equivocada lanzan excepción en
/// decrypt(), a diferencia del CBC anterior que no detectaba manipulación.
///
/// wrapKeyRsaOaep envuelve la clave AES con la pública RSA-OAEP-SHA256 de
/// Cloud KMS para el flujo de key escrow (ver docs/superpowers/specs/
/// 2026-07-10-panic-key-escrow-design.md).
class EncryptionUtil {
  EncryptionUtil._();

  static const int _keyLength = 32; // 256 bits
  static const int _gcmIvLength = 12; // 96 bits — tamaño recomendado NIST para GCM
  static const int _gcmTagLength = 16; // 128 bits

  static Uint8List generateKey() => enc.Key.fromSecureRandom(_keyLength).bytes;

  static Uint8List encrypt(Uint8List plaintext, Uint8List keyBytes) {
    final key = enc.Key(keyBytes);
    final iv = enc.IV.fromSecureRandom(_gcmIvLength);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.gcm));
    final encrypted = encrypter.encryptBytes(plaintext, iv: iv);
    return Uint8List.fromList([...iv.bytes, ...encrypted.bytes]);
  }

  static Uint8List decrypt(Uint8List blob, Uint8List keyBytes) {
    if (blob.length < _gcmIvLength + _gcmTagLength) {
      throw ArgumentError('Blob cifrado inválido: demasiado corto');
    }
    final key = enc.Key(keyBytes);
    final iv = enc.IV(Uint8List.fromList(blob.sublist(0, _gcmIvLength)));
    final ciphertextAndTag = enc.Encrypted(Uint8List.fromList(blob.sublist(_gcmIvLength)));
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.gcm));
    return Uint8List.fromList(encrypter.decryptBytes(ciphertextAndTag, iv: iv));
  }

  static Uint8List wrapKeyRsaOaep(Uint8List aesKey, String publicKeyPem) {
    final publicKey = CryptoUtils.rsaPublicKeyFromPem(publicKeyPem);
    final cipher = pc.OAEPEncoding.withSHA256(pc.RSAEngine())
      ..init(true, pc.PublicKeyParameter<pc.RSAPublicKey>(publicKey));
    return cipher.process(aesKey);
  }
}
```

- [ ] **Step 5: Correr el test y verificar que pasa**

Run: `cd mobile && flutter test test/core/utils/encryption_util_test.dart`
Expected: PASS (7 tests)

- [ ] **Step 6: Commit**

```bash
git add mobile/lib/core/utils/encryption_util.dart mobile/test/core/utils/encryption_util_test.dart mobile/pubspec.yaml mobile/pubspec.lock
git commit -m "feat(mobile): migra cifrado de grabaciones a AES-256-GCM y agrega wrap RSA-OAEP"
```

---

## Task 8: Mobile — `EscrowRemoteDataSource`

**Files:**
- Create: `mobile/lib/features/panic/data/datasources/escrow_remote_datasource.dart`
- Test: `mobile/test/features/panic/data/datasources/escrow_remote_datasource_test.dart`

**Interfaces:**
- Produces: `EscrowRemoteDataSource` (abstracta) con `fetchPublicKey(): Future<({String pem, String keyVersion})>`, `submitEscrowKey({required String sessionId, required String wrappedKeyBase64, required String kmsKeyVersion}): Future<void>`, `registerBlock({required String sessionId, required int blockIndex, required String storagePath}): Future<void>` — usado por Task 9 (`EscrowKeySubmitter`) y Task 10 (`PanicUploadService`).

- [ ] **Step 1: Escribir el test que falla**

Crear `mobile/test/features/panic/data/datasources/escrow_remote_datasource_test.dart`:
```dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:alertaya/features/panic/data/datasources/escrow_remote_datasource.dart';

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.handler);
  final Future<ResponseBody> Function(RequestOptions options) handler;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) => handler(options);
}

ResponseBody _jsonResponse(Map<String, dynamic> body, int statusCode) {
  final bytes = utf8.encode(jsonEncode(body));
  return ResponseBody.fromBytes(
    bytes,
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

void main() {
  late Dio dio;
  late EscrowRemoteDataSourceImpl dataSource;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'https://api.test'));
    dataSource = EscrowRemoteDataSourceImpl(dio);
  });

  group('fetchPublicKey', () {
    test('devuelve el PEM y la versión cuando el backend responde 200', () async {
      dio.httpClientAdapter = _FakeAdapter((options) async {
        expect(options.path, '/panic/escrow/public-key');
        return _jsonResponse({
          'publicKeyPem': '-----BEGIN PUBLIC KEY-----\nABC\n-----END PUBLIC KEY-----',
          'kmsKeyVersion': '1',
        }, 200);
      });

      final result = await dataSource.fetchPublicKey();

      expect(result.pem, contains('BEGIN PUBLIC KEY'));
      expect(result.keyVersion, '1');
    });
  });

  group('submitEscrowKey', () {
    test('envía el wrapped key al endpoint correcto con algorithm fijo', () async {
      RequestOptions? captured;
      dio.httpClientAdapter = _FakeAdapter((options) async {
        captured = options;
        return _jsonResponse({}, 201);
      });

      await dataSource.submitEscrowKey(
        sessionId: 'ses-1',
        wrappedKeyBase64: 'd2FubmVk',
        kmsKeyVersion: '1',
      );

      expect(captured!.path, '/panic/sessions/ses-1/escrow-key');
      expect(captured!.method, 'POST');
      expect(captured!.data, {
        'wrappedKey': 'd2FubmVk',
        'kmsKeyVersion': '1',
        'algorithm': 'RSA_OAEP_256',
      });
    });
  });

  group('registerBlock', () {
    test('registra el bloque subido en el endpoint correcto', () async {
      RequestOptions? captured;
      dio.httpClientAdapter = _FakeAdapter((options) async {
        captured = options;
        return _jsonResponse({}, 201);
      });

      await dataSource.registerBlock(
        sessionId: 'ses-1',
        blockIndex: 2,
        storagePath: 'gs://bucket/path.bin',
      );

      expect(captured!.path, '/panic/sessions/ses-1/blocks');
      expect(captured!.data, {'blockIndex': 2, 'storagePath': 'gs://bucket/path.bin'});
    });
  });
}
```

- [ ] **Step 2: Correr el test y verificar que falla**

Run: `cd mobile && flutter test test/features/panic/data/datasources/escrow_remote_datasource_test.dart`
Expected: FAIL — módulo no encontrado

- [ ] **Step 3: Implementar `EscrowRemoteDataSource`**

Crear `mobile/lib/features/panic/data/datasources/escrow_remote_datasource.dart`:
```dart
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import 'package:alertaya/core/errors/exceptions.dart';

abstract class EscrowRemoteDataSource {
  Future<({String pem, String keyVersion})> fetchPublicKey();

  Future<void> submitEscrowKey({
    required String sessionId,
    required String wrappedKeyBase64,
    required String kmsKeyVersion,
  });

  Future<void> registerBlock({
    required String sessionId,
    required int blockIndex,
    required String storagePath,
  });
}

@LazySingleton(as: EscrowRemoteDataSource)
class EscrowRemoteDataSourceImpl implements EscrowRemoteDataSource {
  const EscrowRemoteDataSourceImpl(this._dio);
  final Dio _dio;

  @override
  Future<({String pem, String keyVersion})> fetchPublicKey() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/panic/escrow/public-key');
      final data = response.data!;
      return (pem: data['publicKeyPem'] as String, keyVersion: data['kmsKeyVersion'] as String);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw const UnauthorizedException();
      throw ServerException(statusCode: e.response?.statusCode ?? 500, message: e.message);
    }
  }

  @override
  Future<void> submitEscrowKey({
    required String sessionId,
    required String wrappedKeyBase64,
    required String kmsKeyVersion,
  }) async {
    try {
      await _dio.post<void>(
        '/panic/sessions/$sessionId/escrow-key',
        data: {
          'wrappedKey': wrappedKeyBase64,
          'kmsKeyVersion': kmsKeyVersion,
          'algorithm': 'RSA_OAEP_256',
        },
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw const UnauthorizedException();
      throw ServerException(statusCode: e.response?.statusCode ?? 500, message: e.message);
    }
  }

  @override
  Future<void> registerBlock({
    required String sessionId,
    required int blockIndex,
    required String storagePath,
  }) async {
    try {
      await _dio.post<void>(
        '/panic/sessions/$sessionId/blocks',
        data: {'blockIndex': blockIndex, 'storagePath': storagePath},
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw const UnauthorizedException();
      throw ServerException(statusCode: e.response?.statusCode ?? 500, message: e.message);
    }
  }
}
```

- [ ] **Step 4: Correr el test y verificar que pasa**

Run: `cd mobile && flutter test test/features/panic/data/datasources/escrow_remote_datasource_test.dart`
Expected: PASS (3 tests)

- [ ] **Step 5: Regenerar la configuración de DI**

Run: `cd mobile && dart run build_runner build --delete-conflicting-outputs`
Expected: `injection.config.dart` incluye el registro de `EscrowRemoteDataSourceImpl`

- [ ] **Step 6: Commit**

```bash
git add mobile/lib/features/panic/data/datasources/escrow_remote_datasource.dart \
        mobile/test/features/panic/data/datasources/escrow_remote_datasource_test.dart \
        mobile/lib/app/di/injection.config.dart
git commit -m "feat(mobile): agrega EscrowRemoteDataSource para el flujo de key escrow"
```

---

## Task 9: Mobile — `EscrowKeySubmitter` y ciclo de vida de la clave en `AudioRecordingService`

**Files:**
- Create: `mobile/lib/features/panic/data/services/escrow_key_submitter.dart`
- Test: `mobile/test/features/panic/data/services/escrow_key_submitter_test.dart`
- Modify: `mobile/lib/features/panic/data/services/audio_recording_service.dart`

**Interfaces:**
- Consumes: `EscrowRemoteDataSource` (Task 8), `EncryptionUtil.wrapKeyRsaOaep` (Task 7).
- Produces: `EscrowKeySubmitter.submit({required String sessionId, required Uint8List aesKey, int attempts}): Future<bool>` — usado por `AudioRecordingService`. `AudioRecordingService.confirmUploadsAndClearKey(): Future<void>` (nuevo método público) — usado por Task 10 (`panic_bloc.dart`).

- [ ] **Step 1: Escribir el test de `EscrowKeySubmitter` que falla**

Crear `mobile/test/features/panic/data/services/escrow_key_submitter_test.dart`:
```dart
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:alertaya/features/panic/data/datasources/escrow_remote_datasource.dart';
import 'package:alertaya/features/panic/data/services/escrow_key_submitter.dart';

const _testPublicKeyPem = '''
-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA7P7cLcLhbz4BEQGfDSz+
Xr3ZXrhBksBwzbVGU9mOrgTvT0OtLpfzOI6+ZzWd/SCmnj3CTcX3ODfWHXwjLryk
d4kjFVOON4YSAT52vbwDvHPFkV8cHYoOcsEeljd+41Hwbr2f1VyZdQAXZLFU8qMq
ZbzYYOYPkljyDoPU4PGjWnLT4L5WL/Cm8qyqcEb4hN/OQ9b/6ZUaHz5zfsYV1hBX
lMoIm/s5UphYiygXhEmSnPxhZa0Qm9lzilsnnYry1PLiPMrWnXQXJzqxr+3DOhqD
zGqOHKIBbxMt5/ysxbUP1vwX+4GxnVHL+1p/rDl2PY00W6NfWfMDfbRQZSAA30bs
TwIDAQAB
-----END PUBLIC KEY-----
''';

class _FakeEscrowRemoteDataSource implements EscrowRemoteDataSource {
  _FakeEscrowRemoteDataSource({this.failCount = 0});

  final int failCount;
  int submitCalls = 0;
  Map<String, dynamic>? lastSubmitArgs;

  @override
  Future<({String pem, String keyVersion})> fetchPublicKey() async {
    return (pem: _testPublicKeyPem, keyVersion: '1');
  }

  @override
  Future<void> submitEscrowKey({
    required String sessionId,
    required String wrappedKeyBase64,
    required String kmsKeyVersion,
  }) async {
    submitCalls++;
    lastSubmitArgs = {
      'sessionId': sessionId,
      'wrappedKeyBase64': wrappedKeyBase64,
      'kmsKeyVersion': kmsKeyVersion,
    };
    if (submitCalls <= failCount) {
      throw Exception('fallo simulado intento $submitCalls');
    }
  }

  @override
  Future<void> registerBlock({
    required String sessionId,
    required int blockIndex,
    required String storagePath,
  }) async {}
}

void main() {
  group('EscrowKeySubmitter', () {
    test('devuelve true y llama submitEscrowKey una vez si no hay fallos', () async {
      final fake = _FakeEscrowRemoteDataSource();
      final submitter = EscrowKeySubmitter(fake);
      final aesKey = Uint8List(32);

      final ok = await submitter.submit(sessionId: 'ses-1', aesKey: aesKey);

      expect(ok, isTrue);
      expect(fake.submitCalls, 1);
      expect(fake.lastSubmitArgs!['sessionId'], 'ses-1');
      expect(fake.lastSubmitArgs!['kmsKeyVersion'], '1');
    });

    test('reintenta hasta lograr éxito dentro del límite de intentos', () async {
      final fake = _FakeEscrowRemoteDataSource(failCount: 2);
      final submitter = EscrowKeySubmitter(fake);
      final aesKey = Uint8List(32);

      final ok = await submitter.submit(sessionId: 'ses-1', aesKey: aesKey, attempts: 3);

      expect(ok, isTrue);
      expect(fake.submitCalls, 3);
    });

    test('devuelve false si se agotan los intentos', () async {
      final fake = _FakeEscrowRemoteDataSource(failCount: 5);
      final submitter = EscrowKeySubmitter(fake);
      final aesKey = Uint8List(32);

      final ok = await submitter.submit(sessionId: 'ses-1', aesKey: aesKey, attempts: 2);

      expect(ok, isFalse);
      expect(fake.submitCalls, 2);
    });
  });
}
```

- [ ] **Step 2: Correr el test y verificar que falla**

Run: `cd mobile && flutter test test/features/panic/data/services/escrow_key_submitter_test.dart`
Expected: FAIL — módulo no encontrado

- [ ] **Step 3: Implementar `EscrowKeySubmitter`**

Crear `mobile/lib/features/panic/data/services/escrow_key_submitter.dart`:
```dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import 'package:alertaya/core/utils/encryption_util.dart';
import 'package:alertaya/features/panic/data/datasources/escrow_remote_datasource.dart';

/// Envuelve la clave AES de una sesión con la pública RSA-OAEP de escrow y
/// la sube al backend, con reintentos con backoff lineal.
@injectable
class EscrowKeySubmitter {
  const EscrowKeySubmitter(this._escrow);
  final EscrowRemoteDataSource _escrow;

  Future<bool> submit({
    required String sessionId,
    required Uint8List aesKey,
    int attempts = 3,
  }) async {
    for (var attempt = 1; attempt <= attempts; attempt++) {
      try {
        final publicKey = await _escrow.fetchPublicKey();
        final wrapped = EncryptionUtil.wrapKeyRsaOaep(aesKey, publicKey.pem);
        await _escrow.submitEscrowKey(
          sessionId: sessionId,
          wrappedKeyBase64: base64Encode(wrapped),
          kmsKeyVersion: publicKey.keyVersion,
        );
        return true;
      } catch (e) {
        debugPrint('[EscrowKeySubmitter] intento $attempt falló: $e');
        if (attempt < attempts) {
          await Future.delayed(Duration(seconds: attempt * 2));
        }
      }
    }
    return false;
  }
}
```

- [ ] **Step 4: Correr el test y verificar que pasa**

Run: `cd mobile && flutter test test/features/panic/data/services/escrow_key_submitter_test.dart`
Expected: PASS (3 tests)

- [ ] **Step 5: Reescribir el ciclo de vida de la clave en `AudioRecordingService`**

En `mobile/lib/features/panic/data/services/audio_recording_service.dart`, agregar el import y cambiar el constructor:
```dart
import 'package:alertaya/features/panic/data/services/escrow_key_submitter.dart';
```
```dart
@lazySingleton
class AudioRecordingService {
  AudioRecordingService(this._storage, this._escrowSubmitter);

  final SecureStorageService _storage;
  final EscrowKeySubmitter _escrowSubmitter;
  final _recorder = AudioRecorder();
  // ... (resto de los campos sin cambios)
  bool _escrowConfirmed = false;
```

Reemplazar `start()`:
```dart
  Future<void> start(String sessionId) async {
    if (_isRecording) return;
    _sessionId = sessionId;
    _blockNumber = 0;
    _isRecording = true;
    _escrowConfirmed = false;

    // Clave AES-256 nueva por sesión — nunca se reutiliza entre pánicos.
    _encryptionKey = EncryptionUtil.generateKey();
    await _storage.write(_kEncryptionKey, base64Encode(_encryptionKey));

    // Escrow en paralelo: no bloquea el inicio de la grabación (emergencia
    // primero), pero stop() no borra la clave hasta que esto confirme.
    unawaited(_submitEscrowKey());

    await _startBlock();

    _blockTimer = Timer.periodic(
      const Duration(minutes: AppConstants.panicBlockMinutes),
      (_) => _rotateBlock(),
    );

    _amplitudeTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) => _emitAmplitude(),
    );
  }

  Future<void> _submitEscrowKey() async {
    _escrowConfirmed = await _escrowSubmitter.submit(
      sessionId: _sessionId!,
      aesKey: _encryptionKey,
    );
  }
```

Reemplazar `stop()` (ya no borra la clave — eso queda para `confirmUploadsAndClearKey`):
```dart
  Future<List<String>> stop() async {
    if (!_isRecording) return [];
    _isRecording = false;

    _blockTimer?.cancel();
    _amplitudeTimer?.cancel();
    _blockTimer = null;
    _amplitudeTimer = null;

    final path = await _stopCurrentBlock();

    _amplitudeController.add(0.0);

    final paths = <String>[];
    if (path != null) paths.add(path);
    return paths;
  }

  /// Se llama después de confirmar que todos los bloques de audio subieron.
  /// Reintenta el escrow una vez más si aún no fue confirmado; solo borra
  /// la clave local si el escrow terminó confirmado — si no, la clave
  /// permanece en secure storage para un reintento en una futura sesión.
  Future<void> confirmUploadsAndClearKey() async {
    if (!_escrowConfirmed) {
      _escrowConfirmed = await _escrowSubmitter.submit(
        sessionId: _sessionId!,
        aesKey: _encryptionKey,
        attempts: 1,
      );
    }
    if (_escrowConfirmed) {
      await _storage.delete(_kEncryptionKey);
    } else {
      debugPrint(
        '[AudioRecordingService] escrow NO confirmado — clave permanece en secure storage',
      );
    }
  }
```

Nota: en `_startBlock`/`_stopCurrentBlock` no hay más cambios — siguen usando `_encryptionKey` para `EncryptionUtil.encrypt`, que ya migró a GCM en Task 7.

- [ ] **Step 6: Regenerar la configuración de DI**

Run: `cd mobile && dart run build_runner build --delete-conflicting-outputs`
Expected: `injection.config.dart` inyecta `EscrowKeySubmitter` en `AudioRecordingService`

- [ ] **Step 7: Correr los tests de mobile para evitar regresiones**

Run: `cd mobile && flutter test test/features/panic`
Expected: PASS (todos los tests de `features/panic`, incluidos los de Tasks 7-9)

- [ ] **Step 8: Commit**

```bash
git add mobile/lib/features/panic/data/services/escrow_key_submitter.dart \
        mobile/test/features/panic/data/services/escrow_key_submitter_test.dart \
        mobile/lib/features/panic/data/services/audio_recording_service.dart \
        mobile/lib/app/di/injection.config.dart
git commit -m "feat(mobile): clave AES por sesión con escrow antes de grabar, sin borrado prematuro"
```

---

## Task 10: Mobile — registrar bloques subidos y esperar uploads antes de limpiar la clave

**Files:**
- Modify: `mobile/lib/core/services/firebase_storage_service.dart`
- Modify: `mobile/lib/features/panic/data/services/panic_upload_service.dart`
- Modify: `mobile/lib/features/panic/presentation/bloc/panic_bloc.dart`

**Interfaces:**
- Consumes: `EscrowRemoteDataSource.registerBlock` (Task 8), `AudioRecordingService.confirmUploadsAndClearKey` (Task 9).
- Produces: `FirebaseStorageService.uploadPanicBlock(...): Future<String?>` (antes `Future<void>`) — cambio de contrato usado internamente por `PanicUploadService`.

Este es el punto exacto que hoy causa la race condition (`panic_bloc.dart:353-371`): `_audioService.stop()` borraba la clave (línea 88 de `audio_recording_service.dart`, ya removida en Task 9) **antes** de que el bloque final terminara de subirse, y los bloques intermedios subían fire-and-forget sin trackear su finalización.

- [ ] **Step 1: Hacer que `uploadPanicBlock` devuelva el `gs://` path**

En `mobile/lib/core/services/firebase_storage_service.dart`, reemplazar el método:
```dart
  /// Sube un bloque de audio cifrado (AES-256-GCM) del pánico.
  /// Los bloques se guardan en: panic/{sessionId}/audio/block_{index}.bin
  /// Devuelve el path gs:// del bloque subido, o null si el archivo local
  /// no existía (no lanza — mismo comportamiento fire-and-forget de antes).
  Future<String?> uploadPanicBlock(
    String filePath,
    String sessionId,
    int blockIndex,
  ) async {
    final file = File(filePath);
    final stat = await FileStat.stat(file.path);
    if (stat.type == FileSystemEntityType.notFound) {
      debugPrint(
          '[FirebaseStorage] SKIP bloque — archivo no existe: $filePath');
      return null;
    }
    final ref = _storage.ref('panic/$sessionId/audio/block_$blockIndex.bin');
    await ref.putFile(
      file,
      SettableMetadata(contentType: 'application/octet-stream'),
    );
    final gsPath = 'gs://${ref.bucket}/${ref.fullPath}';
    debugPrint('[FirebaseStorage] bloque OK → $gsPath');
    return gsPath;
  }
```

- [ ] **Step 2: Hacer que `PanicUploadService` registre el bloque en el backend**

Reemplazar el contenido completo de `mobile/lib/features/panic/data/services/panic_upload_service.dart`:
```dart
import 'package:injectable/injectable.dart';

import 'package:alertaya/core/services/firebase_storage_service.dart';
import 'package:alertaya/features/panic/data/datasources/escrow_remote_datasource.dart';

@lazySingleton
class PanicUploadService {
  const PanicUploadService(this._storageService, this._escrow);

  final FirebaseStorageService _storageService;
  final EscrowRemoteDataSource _escrow;

  /// Sube un bloque de audio cifrado a Storage y, si la subida tuvo éxito,
  /// avisa al backend (POST /panic/sessions/:id/blocks) para que quede
  /// asociado a la sesión — sin esto, la web de autoridades no puede
  /// ubicar el bloque aunque tenga la clave.
  Future<void> uploadBlock(
    String filePath,
    String sessionId,
    int blockIndex,
  ) async {
    final gsPath = await _storageService.uploadPanicBlock(filePath, sessionId, blockIndex);
    if (gsPath == null) return;
    await _escrow.registerBlock(
      sessionId: sessionId,
      blockIndex: blockIndex,
      storagePath: gsPath,
    );
  }
}
```

- [ ] **Step 3: Trackear uploads pendientes y esperar antes de limpiar la clave en `panic_bloc.dart`**

Agregar el campo nuevo junto a las demás `StreamSubscription` (cerca de la línea 78-79 de `mobile/lib/features/panic/presentation/bloc/panic_bloc.dart`):
```dart
  final List<Future<void>> _pendingUploads = [];
```

Reemplazar `_onBlockCompleted`:
```dart
  void _onBlockCompleted(
    _PanicBlockCompleted event,
    Emitter<PanicState> emit,
  ) {
    if (state is! PanicActive) return;
    final current = state as PanicActive;

    final blockIndex = current.session.currentBlock - 1;
    debugPrint(
        '[PanicBloc] Bloque completado: currentBlock=${current.session.currentBlock} blockIndex=$blockIndex');
    // Fire-and-forget para no bloquear la grabación del siguiente bloque,
    // pero trackeado en _pendingUploads para poder esperarlo en stop().
    final upload = _uploadService
        .uploadBlock(event.filePath, current.session.id, blockIndex)
        .catchError((dynamic e) {
      debugPrint('[PanicBloc] Upload bloque $blockIndex falló: $e');
    });
    _pendingUploads.add(upload);
    unawaited(upload);

    final updatedPaths = [...current.session.recordingPaths, event.filePath];
    emit(current.copyWith(
      session: current.session.copyWith(
        recordingPaths: updatedPaths,
        currentBlock: current.session.currentBlock + 1,
      ),
    ));
  }
```

Reemplazar `_stopRecording`:
```dart
  Future<void> _stopRecording([PanicActive? activeState]) async {
    _locationTracker.stop();
    await _amplitudeSub?.cancel();
    await _blockSub?.cancel();
    _amplitudeSub = null;
    _blockSub = null;

    final finalAudioPaths = await _audioService.stop();
    debugPrint('[PanicBloc] _stopRecording — audio: $finalAudioPaths');

    if (activeState != null) {
      // Subir bloque de audio parcial final
      if (finalAudioPaths.isNotEmpty) {
        final blockIndex = activeState.session.currentBlock - 1;
        debugPrint(
            '[PanicBloc] Subiendo bloque audio final — blockIndex=$blockIndex');
        try {
          await _uploadService
              .uploadBlock(
                  finalAudioPaths.first, activeState.session.id, blockIndex)
              .timeout(const Duration(seconds: 30));
          debugPrint('[PanicBloc] Upload bloque audio OK');
        } catch (e) {
          debugPrint('[PanicBloc] Upload bloque audio FALLÓ: $e');
        }
      }

      // Espera los bloques intermedios que quedaron subiendo en background
      // ANTES de dejar que se confirme/limpie la clave — sin esto, un bloque
      // que todavía no terminó de subir se queda huérfano sin clave asociada.
      try {
        await Future.wait(_pendingUploads).timeout(const Duration(seconds: 30));
      } catch (e) {
        debugPrint('[PanicBloc] Espera de uploads pendientes falló: $e');
      }
      _pendingUploads.clear();

      await _audioService.confirmUploadsAndClearKey();
    }

    await _channelService.stopService();
  }
```

- [ ] **Step 4: Correr los tests de mobile para evitar regresiones**

Run: `cd mobile && flutter test`
Expected: PASS (toda la suite, sin regresiones en `panic_bloc_test.dart` si existe, ni en los tests de Tasks 7-9)

- [ ] **Step 5: Regenerar la configuración de DI**

Run: `cd mobile && dart run build_runner build --delete-conflicting-outputs`
Expected: `injection.config.dart` inyecta `EscrowRemoteDataSource` en `PanicUploadService`

- [ ] **Step 6: Commit**

```bash
git add mobile/lib/core/services/firebase_storage_service.dart \
        mobile/lib/features/panic/data/services/panic_upload_service.dart \
        mobile/lib/features/panic/presentation/bloc/panic_bloc.dart \
        mobile/lib/app/di/injection.config.dart
git commit -m "fix(mobile): espera uploads pendientes y registra bloques antes de limpiar la clave de escrow"
```

---

## Fuera de alcance de este plan

- UI de la plataforma web de autoridades (reproductor + botón de "solicitar clave" + descifrado WebCrypto). Este plan deja listo el contrato de endpoints (`GET /panic/escrow/public-key`, `POST /panic/sessions/:id/recordings/access`) que esa UI deberá consumir.
- Aprovisionamiento de la infraestructura Cloud KMS en sí (crear el key ring / crypto key / IAM bindings en GCP) — es un paso de operaciones, no de código; documentado en el diseño (`docs/superpowers/specs/2026-07-10-panic-key-escrow-design.md`, sección "Cloud KMS — setup").
- Retención/expiración automática de audios o claves de escrow.
- Doble aprobación (four-eyes) para el acceso a claves.
