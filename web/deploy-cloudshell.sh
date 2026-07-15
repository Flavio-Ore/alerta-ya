#!/bin/bash
# AlertaYa Web Panel — Deploy to Google Cloud Run via Cloud Shell
#
# This script is designed to run inside Google Cloud Shell in your browser.
#
# Usage:
# 1. Open Google Cloud Shell (https://shell.cloud.google.com).
# 2. Clone your repository:
#    git clone https://github.com/Flavio-Ore/alerta-ya.git
#    cd alerta-ya
# 3. Make this script executable and run it:
#    chmod +x web/deploy-cloudshell.sh
#    ./web/deploy-cloudshell.sh

set -e

# Configuration
SERVICE_NAME="alertaya-web"
REGION="us-central1"

echo "=== AlertaYa Frontend Web Panel GCP Cloud Run Deployer ==="

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

# Ask for the deployed API URL
read -p "Enter the deployed API URL (e.g. https://alertaya-api-xxxx-uc.a.run.app): " API_URL

if [ -z "$API_URL" ]; then
  echo "❌ Error: API URL is required."
  exit 1
fi

# Construct WebSocket URL from API URL (replace https:// with wss://)
WS_URL=$(echo "$API_URL" | sed 's/http/ws/')

echo "Deploying web service '$SERVICE_NAME' in project '$PROJECT_ID' region '$REGION'..."
echo "API URL: $API_URL"
echo "WebSocket URL: $WS_URL"

# Deploy to Cloud Run using source directory deployment (which builds using Cloud Build)
gcloud run deploy "$SERVICE_NAME" \
  --source ./web \
  --region "$REGION" \
  --allow-unauthenticated \
  --set-env-vars="VITE_API_BASE_URL=$API_URL,VITE_WS_URL=$WS_URL"

echo "✅ Web Panel successfully deployed!"
