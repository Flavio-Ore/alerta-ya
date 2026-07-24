#!/bin/bash
set -e

# =====================================================================
# Script de Despliegue Unificado para AlertaYa en GCP (Google Cloud Shell)
# =====================================================================

PROJECT_ID="alertaya-1b963"
REGION="us-central1"
AR_REPO="cloud-run-source-deploy"

API_IMAGE="us-central1-docker.pkg.dev/$PROJECT_ID/$AR_REPO/alertaya-api:latest"
WEB_IMAGE="us-central1-docker.pkg.dev/$PROJECT_ID/$AR_REPO/alertaya-web:latest"
ML_IMAGE="us-central1-docker.pkg.dev/$PROJECT_ID/$AR_REPO/alertaya-ml:latest"

echo "--------------------------------------------------"
echo "🚀 Iniciando despliegue unificado en GCP..."
echo "--------------------------------------------------"

# 1. Asegurar credenciales de Docker en Artifact Registry
echo "🔐 Configurando autenticación de Docker con Artifact Registry..."
gcloud auth configure-docker us-central1-docker.pkg.dev --quiet

# =====================================================================
# 🤖 DESPLIEGUE 1: ML SERVICE
# =====================================================================
echo ""
echo "--------------------------------------------------"
echo "🤖 1. Compilando y Desplegando ML Service..."
echo "--------------------------------------------------"
docker build -t "$ML_IMAGE" ./ml
docker push "$ML_IMAGE"

# Aplicar ml/service.yaml (fuente de verdad de env vars + secrets)
gcloud run services replace ml/service.yaml --region="$REGION"
gcloud run services add-iam-policy-binding alertaya-ml \
  --region="$REGION" --member="allUsers" --role="roles/run.invoker" --quiet

# =====================================================================
# ⚡ DESPLIEGUE 2: BACKEND API
# =====================================================================
echo ""
echo "--------------------------------------------------"
echo "⚡ 2. Compilando y Desplegando Backend API (con Redis Sidecar)..."
echo "--------------------------------------------------"
docker build -t "$API_IMAGE" ./api
docker push "$API_IMAGE"

# Aplicar api/service.yaml (sidecar redis + secrets de Secret Manager)
gcloud run services replace api/service.yaml --region="$REGION"
gcloud run services add-iam-policy-binding alertaya-api \
  --region="$REGION" --member="allUsers" --role="roles/run.invoker" --quiet

# =====================================================================
# 🌐 DESPLIEGUE 3: WEB PANEL (FRONTEND)
# =====================================================================
echo ""
echo "--------------------------------------------------"
echo "🌐 3. Compilando y Desplegando Web Panel..."
echo "--------------------------------------------------"

# Escribir el .env necesario para compilar el cliente React estático
cat << EOF > web/.env
VITE_API_BASE_URL=https://alertaya-api-562740646244.us-central1.run.app
VITE_WS_URL=wss://alertaya-api-562740646244.us-central1.run.app

VITE_FIREBASE_API_KEY=AIzaSyA4uKjyHk7DkzbghZ-ZsErvnolPRM6N2is
VITE_FIREBASE_AUTH_DOMAIN=alertaya-1b963.firebaseapp.com
VITE_FIREBASE_PROJECT_ID=alertaya-1b963
VITE_FIREBASE_STORAGE_BUCKET=alertaya-1b963.firebasestorage.app
VITE_FIREBASE_MESSAGING_SENDER_ID=562740646244
VITE_FIREBASE_APP_ID=1:562740646244:web:f79733afe076dbc47daa71
EOF

docker build -t "$WEB_IMAGE" ./web
docker push "$WEB_IMAGE"

# Aplicar web/service.yaml
gcloud run services replace web/service.yaml --region="$REGION"
gcloud run services add-iam-policy-binding alertaya-web \
  --region="$REGION" --member="allUsers" --role="roles/run.invoker" --quiet

echo ""
echo "=================================================="
echo "🎉 ¡Despliegue de todos los servicios completado!"
echo "=================================================="
echo "🤖 ML Service:   https://alertaya-ml-562740646244.us-central1.run.app"
echo "⚡ API Backend:  https://alertaya-api-562740646244.us-central1.run.app"
echo "🌐 Web Panel:    https://alertaya-web-562740646244.us-central1.run.app"
echo "=================================================="
