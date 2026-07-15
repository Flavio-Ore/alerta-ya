#!/bin/bash
# AlertaYa API — Deploy to Google Cloud Run via Cloud Shell
#
# This script is designed to run inside Google Cloud Shell in your browser.
#
# Usage:
# 1. Open Google Cloud Shell (https://shell.cloud.google.com).
# 2. Clone your repository:
#    git clone https://github.com/Flavio-Ore/alerta-ya.git
#    cd alerta-ya
# 3. Make this script executable and run it:
#    chmod +x api/deploy-cloudshell.sh
#    ./api/deploy-cloudshell.sh

set -e

# Configuration
SERVICE_NAME="alertaya-api"
REGION="us-central1"

echo "=== AlertaYa Backend API GCP Cloud Run Deployer ==="

# Check if authenticated
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q "@"; then
  echo "❌ Error: You are not authenticated with gcloud. Run 'gcloud auth login' or open this in Google Cloud Shell."
  exit 1
fi

PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
if [ -z "$PROJECT_ID" ]; then
  echo "❌ Error: No default GCP project selected. Set it via 'gcloud config set project YOUR_PROJECT_ID'."
  exit 1
fi

echo "Deploying service '$SERVICE_NAME' in project '$PROJECT_ID' region '$REGION'..."

# Deploy to Cloud Run using source directory deployment (which builds using Cloud Build)
gcloud run deploy "$SERVICE_NAME" \
  --source ./api \
  --region "$REGION" \
  --allow-unauthenticated \
  --set-env-vars="NODE_ENV=production,PORT=3000"

echo "✅ API successfully deployed!"
echo "Please configure the remaining database and secret variables in the Cloud Run Console or via command line:"
echo "  - DATABASE_URL (Cloud SQL instance Connection URL)"
echo "  - REDIS_URL (GCP Memorystore IP)"
echo "  - JWT_SECRET"
echo "  - JOB_SECRET"
echo "  - FIREBASE_STORAGE_BUCKET"
echo "  - KMS_PROJECT_ID"
