# DATA_MODELS.md — Modelos de Datos AlertaYa

---

## PostgreSQL — Prisma Schema (referencia)

### users
```prisma
model User {
  id              String   @id @default(uuid())
  firebaseUid     String   @unique                 // Cifrado en reposo
  reputationScore Int      @default(100)
  createdAt       DateTime @default(now())
  // NUNCA almacenar email/nombre en texto plano aquí
  // Los datos de identidad van en tabla separada cifrada
  reports         Report[]
  panicSessions   PanicSession[]
}
```

### incidents (incidentes publicados — anónimos)
```prisma
model Incident {
  id              String          @id @default(uuid())
  type            IncidentType    // ROBBERY, ACCIDENT, HARASSMENT, EXTORTION, SUSPICIOUS
  severity        Severity        // LOW, MODERATE, CRITICAL
  status          IncidentStatus  // ACTIVE, IN_ATTENTION, CLOSED
  lat             Float
  lng             Float
  district        String
  confirmCount    Int             @default(0)
  denyCount       Int             @default(0)
  reportCount     Int             @default(1)
  expiresAt       DateTime
  createdAt       DateTime        @default(now())
  updatedAt       DateTime        @updatedAt
  reports         Report[]        // Reportes individuales que forman el incidente
  unitAssigned    String?         // ID de unidad operativa
}
```

### reports (reportes individuales — la identidad nunca sale de aquí)
```prisma
model Report {
  id              String        @id @default(uuid())
  incidentId      String?       // null = aún no alcanzó threshold
  userId          String        // Solo para rate limiting interno, NUNCA expuesto
  formData        Json          // JSONB: respuestas del formulario dinámico
  mediaUrls       String[]      // URLs en GCS — cifradas
  lat             Float
  lng             Float
  aiVerified      Boolean?
  aiScore         Float?
  createdAt       DateTime      @default(now())
  user            User          @relation(...)
  incident        Incident?     @relation(...)
}
// formData JSONB example:
// {
//   "incidentType": "ROBBERY",
//   "personsInvolved": "2_3",
//   "weapon": "firearm",
//   "stillInArea": true,
//   "fleeDirection": "unknown"
// }
```

### panic_sessions
```prisma
model PanicSession {
  id              String    @id @default(uuid())
  userId          String
  startedAt       DateTime  @default(now())
  endedAt         DateTime?
  recordingUrls   String[]  // GCS URLs — cifradas AES-256
  lat             Float
  lng             Float
  status          PanicStatus // ACTIVE, DEACTIVATED, TIMEOUT
  deactivatedBy   String?   // "pin" | "timeout"
  user            User      @relation(...)
}
```

### risk_zones (caché de predicciones IA)
```prisma
model RiskZone {
  id              String    @id @default(uuid())
  district        String
  lat             Float
  lng             Float
  riskScore       Int       // 0–100
  predictedHour   Int       // 0–23
  updatedAt       DateTime  @updatedAt
}
```

---

## Redis — Estructuras

```
# Rate limiting por usuario
rate:report:{userId}              → TTL 3600s, value = count (max 3)
rate:push:{userId}:{zone}:{type}  → TTL 180s, value = "1" (push cooldown)

# Threshold engine por incidente
threshold:{lat}:{lng}:{type}     → Hash:
  count         → número de reportes
  firstReportAt → timestamp
  reportIds     → lista de IDs
  formWeapon    → count de "arma de fuego"
  formStillHere → count de "sigue en zona"
  formInjured   → count de "heridos visibles"

# Confirmaciones Waze
confirm:{incidentId}:yes  → count
confirm:{incidentId}:no   → count

# Geofencing cooldown
geofence:{userId}:{district} → TTL 180s, value = "1"
```

---

## Enums

```typescript
enum IncidentType {
  ROBBERY     = "ROBBERY",
  ACCIDENT    = "ACCIDENT",
  HARASSMENT  = "HARASSMENT",
  EXTORTION   = "EXTORTION",
  SUSPICIOUS  = "SUSPICIOUS",
}

enum Severity {
  LOW      = "LOW",       // LEVE
  MODERATE = "MODERATE",  // MODERADO
  CRITICAL = "CRITICAL",  // CRÍTICO
}

enum IncidentStatus {
  ACTIVE       = "ACTIVE",
  IN_ATTENTION = "IN_ATTENTION",
  CLOSED       = "CLOSED",
}
```

---

## Formulario dinámico — JSON Schema por tipo

### ROBBERY
```json
{
  "personsInvolved": "one|two_three|group|unknown",
  "weapon":          "firearm|blade|none|unknown",
  "stillInArea":     "yes|fled_foot|fled_vehicle|unknown",
  "fleeDirection":   "north|south|east|west|unknown"
}
```

### ACCIDENT
```json
{
  "injured":          "yes|no|unknown",
  "vehicleCount":     "one|two|more",
  "blocksTraffic":    "fully|partially|no",
  "medicalPresent":   "yes|no|incoming"
}
```

---

## API Response types — endpoints principales

```typescript
// GET /incidents/active — público (sin identidad)
interface ActiveIncidentResponse {
  id: string;
  type: IncidentType;
  severity: Severity;
  lat: number;
  lng: number;
  district: string;
  confirmCount: number;
  denyCount: number;
  reportCount: number;
  expiresAt: string;
  // formSummary: resumen agregado (nunca datos individuales)
  formSummary: {
    weaponReported: boolean;    // true si 1+ usuarios marcaron arma
    stillInArea: boolean;
    topWeaponType?: string;     // "firearm" si mayoría lo marcó
  };
}

// POST /reports — autenticado
interface CreateReportRequest {
  type: IncidentType;
  lat: number;
  lng: number;
  formData: Record<string, string>;  // Respuestas del formulario
  mediaUrls?: string[];              // Pre-signed URLs ya subidos
}

// POST /incidents/:id/confirm — autenticado  
interface ConfirmIncidentRequest {
  action: "still_here" | "gone";
}
```
