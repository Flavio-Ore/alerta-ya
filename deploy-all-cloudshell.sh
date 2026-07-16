#!/bin/bash
# ==============================================================================
# Script de Despliegue Completo para Google Cloud Shell
# AlertaYa Platform (ML, API + Redis Sidecar, Web Panel)
# ==============================================================================

set -e # Terminar script si algún comando falla

PROJECT_ID="alertaya-1b963"
REGION="us-central1"
REGISTRY_URL="us-central1-docker.pkg.dev/${PROJECT_ID}/cloud-run-source-deploy"

echo "=========================================="
echo "🚀 INICIANDO DESPLIEGUE COMPLETO ALERTAYA"
echo "=========================================="

# 1. ML Service
echo "----------------------------------------"
echo "🤖 1. Compilando y Desplegando ML Service..."
docker build -t ${REGISTRY_URL}/alertaya-ml:latest ./ml
docker push ${REGISTRY_URL}/alertaya-ml:latest

gcloud run deploy alertaya-ml \
  --image=${REGISTRY_URL}/alertaya-ml:latest \
  --region=${REGION} \
  --allow-unauthenticated \
  --set-env-vars="ENVIRONMENT=production,API_URL=https://alertaya-api-562740646244.us-central1.run.app,VERIFIER_MODEL_PATH=src/models/verifier_v1.joblib,PREDICTOR_MODEL_PATH=src/models/predictor_v1.joblib" \
  --set-secrets="DATABASE_URL=alertaya-db-url:latest"

# 2. API Service (con Sidecar Redis)
echo "----------------------------------------"
echo "⚡ 2. Compilando y Desplegando API Backend..."
docker build -t ${REGISTRY_URL}/alertaya-api:latest ./api
docker push ${REGISTRY_URL}/alertaya-api:latest

gcloud run services replace service.yaml --region=${REGION}

# 3. Web Service
echo "----------------------------------------"
echo "🌐 3. Generando configuración de entorno y Compilando Web Panel..."
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

docker build -t ${REGISTRY_URL}/alertaya-web:latest ./web
docker push ${REGISTRY_URL}/alertaya-web:latest

gcloud run deploy alertaya-web \
  --image=${REGISTRY_URL}/alertaya-web:latest \
  --region=${REGION} \
  --allow-unauthenticated

echo "=========================================="
echo "✅ DESPLIEGUE FINALIZADO EXITOSAMENTE"
echo "=========================================="
