# DEPLOYMENT.md — Despliegue en Google Cloud Platform

Runbook para reproducir el despliegue de AlertaYa en GCP desde cero. Pensado para
que, si el proyecto GCP fue eliminado (ver sección "Dar de baja"), levantarlo de
nuevo sea mecánico y no dependa de memoria ni de clicks en la consola.

Proyecto de referencia usado en la sustentación: `alertaya-1b963` (región `us-central1`).
Si volvés a desplegar, creá un proyecto nuevo y reemplazá el `PROJECT_ID` en todo este documento.

---

## 1. Arquitectura de despliegue

```
Cloud Run (alertaya-api)  ── api/service.yaml → Express API + sidecar Redis
Cloud Run (alertaya-ml)   ── ml/service.yaml  → FastAPI (verificación + predicción)
Cloud Run (alertaya-web)  ── web/service.yaml → SPA estático (Vite, build-time env)
Cloud SQL (Postgres 16 + PostGIS) ── 1 sola instancia, base `alertaya_prod`
Secret Manager  ── DATABASE_URL, JWT_SECRET, JOB_SECRET, GLM_API_KEY
Cloud KMS       ── keyring `panic-escrow` (cifrado de grabaciones del botón de pánico)
Artifact Registry (Docker) ── repo `cloud-run-source-deploy`
Firebase (mismo proyecto GCP) ── Auth, Cloud Messaging (push), Storage
```

`api` es el único servicio con sidecar (Redis in-process, no gestionado — se pierde
en cada restart del contenedor; está bien para el volumen de la demo, no para producción real).

---

## 2. Bootstrap del proyecto GCP (una sola vez)

```bash
PROJECT_ID="alertaya-<nuevo-id>"
REGION="us-central1"

gcloud projects create "$PROJECT_ID"
gcloud config set project "$PROJECT_ID"
# Vincular billing account manualmente en la consola (no tiene comando directo simple)

gcloud services enable \
  run.googleapis.com \
  cloudbuild.googleapis.com \
  artifactregistry.googleapis.com \
  sqladmin.googleapis.com \
  secretmanager.googleapis.com \
  cloudkms.googleapis.com \
  firebase.googleapis.com \
  fcm.googleapis.com

gcloud artifacts repositories create cloud-run-source-deploy \
  --repository-format=docker --location="$REGION"
```

Firebase: agregar el proyecto GCP existente desde [console.firebase.google.com](https://console.firebase.google.com)
→ "Add project" → seleccionar el proyecto GCP recién creado. Habilitar Auth
(método que use la app), Cloud Messaging y Storage.

### 2.1 Cloud SQL

```bash
gcloud sql instances create alertaya-db \
  --database-version=POSTGRES_16 \
  --tier=db-f1-micro \
  --region="$REGION"

gcloud sql databases create alertaya_prod --instance=alertaya-db

gcloud sql users set-password postgres --instance=alertaya-db --password="<password-fuerte>"
```

Habilitar PostGIS conectándose a la base (`CREATE EXTENSION postgis;`) y correr
las migraciones de Prisma (`cd api && bunx prisma migrate deploy`) apuntando a esta instancia.

> **No crear una segunda instancia "de prueba" y dejarla activa.** Así se generó
> `alertaya-postgres`, huérfana, en el despliegue anterior — ver sección 4.

### 2.2 Secret Manager

```bash
echo -n "postgresql://postgres:<password>@<IP_PUBLICA_SQL>:5432/alertaya_prod" | \
  gcloud secrets create alertaya-db-url --data-file=-

echo -n "$(openssl rand -base64 32)" | gcloud secrets create alertaya-jwt-secret --data-file=-
echo -n "$(openssl rand -base64 24)" | gcloud secrets create alertaya-job-secret --data-file=-
echo -n "<tu-glm-api-key>"            | gcloud secrets create alertaya-glm-api-key --data-file=-
```

### 2.3 Cloud KMS (cifrado de grabaciones de pánico)

```bash
gcloud kms keyrings create panic-escrow --location=global
gcloud kms keys create panic-escrow-key \
  --keyring=panic-escrow --location=global --purpose=encryption
```

---

## 3. Variables de entorno

Cada servicio tiene su `.env.example` documentado — usalo como referencia para
completar `.env` local:

| Servicio | Archivo |
|----------|---------|
| API | `api/.env.example` |
| ML | `ml/.env.example` |
| Web | `web/.env.example` |
| Mobile | `mobile/.env.example` |

Para Cloud Run, la fuente de verdad **son los manifests versionados**, no la consola:

| Servicio | Manifest |
|----------|----------|
| API | `api/service.yaml` |
| ML | `ml/service.yaml` |
| Web | `web/service.yaml` |

Si agregás o cambiás una variable manualmente desde la consola de Cloud Run,
**replicá el cambio en el manifest correspondiente en el mismo momento**. Si no,
el próximo `gcloud run services replace` la pisa y se pierde silenciosamente —
así se desincronizó `GLM_API_URL` / `GLM_MODEL` la vez pasada.

`web/service.yaml` no lleva variables de entorno a propósito: es un SPA de Vite,
las `VITE_*` se hornean en **build time** desde `web/.env` (lo escribe
`deploy-all.sh` antes del `docker build`). Cualquier env var puesta en runtime
en ese servicio de Cloud Run no tiene ningún efecto — si la ves en la consola,
es ruido de un intento anterior de arreglar algo que no era el problema.

---

## 4. Desplegar

```bash
chmod +x deploy-all.sh
./deploy-all.sh
```

El script compila y sube las 3 imágenes a Artifact Registry, aplica los 3
manifests con `gcloud run services replace` y otorga acceso público
(`roles/run.invoker` a `allUsers`) a cada servicio la primera vez.

Alternativa: `cloudbuild.yaml` en la raíz reproduce el mismo flujo como
Cloud Build remoto (`gcloud builds submit --config=cloudbuild.yaml`). Es
independiente del trigger de Cloud Build conectado a GitHub (si configurás
"Continuous Deployment" desde la consola de Cloud Run sobre el repo, GCP
crea su propio trigger autogenerado — no lee `cloudbuild.yaml` de la raíz,
solo hace `docker build` + `gcloud run services update` con el Dockerfile de
`api/`). Son dos caminos de deploy independientes; no hace falta tener los dos.
