#!/bin/bash
# AlertaYa — Deploy stack on GCP VM using Docker Compose
#
# This script should be executed inside your GCP Compute Engine VM.
#
# Usage:
# 1. SSH into the VM: gcloud compute ssh alertaya-free-db --zone=us-central1-a
# 2. Clone the repo and navigate to it:
#    git clone https://github.com/Flavio-Ore/alerta-ya.git
#    cd alerta-ya
# 3. Make this script executable and run it:
#    chmod +x deploy-vm.sh
#    ./deploy-vm.sh

set -e

echo "=== AlertaYa VM Docker Compose Deployer ==="

# 1. Detect public IP address
PUBLIC_IP=$(curl -s https://api.ipify.org || curl -s https://ifconfig.me || echo "YOUR_VM_PUBLIC_IP")
echo "Detected VM Public IP: $PUBLIC_IP"

# 2. Setup Web environment variables dynamically
echo "Configuring Web Frontend to connect to http://$PUBLIC_IP:3000..."
cat << EOF > web/.env
VITE_API_BASE_URL=http://$PUBLIC_IP:3000
VITE_WS_URL=ws://$PUBLIC_IP:3000
EOF

# 3. Check for API environment file
if [ ! -f api/.env ]; then
  echo "⚠️ Warning: api/.env not found. Creating a default configuration..."
  cat << EOF > api/.env
NODE_ENV=production
PORT=3000
DATABASE_URL=postgresql://alertaya:alertaya@postgres:5432/alertaya_prod
REDIS_URL=redis://redis:6379
JWT_SECRET=production-secret-key-change-this-to-something-secure-min-32-chars
JOB_SECRET=production-job-secret-change-this-min-16-chars
KMS_PROJECT_ID=alertaya-1b963
KMS_LOCATION_ID=global
KMS_KEY_RING_ID=panic-escrow
KMS_KEY_ID=panic-escrow-key
KMS_KEY_VERSION=1
EOF
  echo "Please edit 'api/.env' later with your actual Firebase/KMS keys if needed."
fi

# 4. Check for ML environment file
if [ ! -f ml/.env ]; then
  echo "Creating default ml/.env..."
  cat << EOF > ml/.env
ENVIRONMENT=production
PORT=8000
DATABASE_URL=postgresql://alertaya:alertaya@postgres:5432/alertaya_prod
API_URL=http://api:3000
EOF
fi

# 5. Build and launch services using Docker Compose
echo "Building and launching Docker containers in the background..."
sudo docker-compose -f docker-compose.prod.yml up --build -d

# 6. Apply database migrations
echo "Waiting for PostgreSQL database to start..."
sleep 5
echo "Running Prisma migrations..."
sudo docker-compose -f docker-compose.prod.yml exec -T api bunx prisma migrate deploy

echo "✅ All services deployed successfully!"
echo "You can access the platform at:"
echo "  - Web Panel: http://$PUBLIC_IP:5173"
echo "  - Backend API: http://$PUBLIC_IP:3000"
