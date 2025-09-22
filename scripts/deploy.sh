#!/bin/bash

echo "🚀 TMS Production Deployment"
echo "============================"

DOMAIN=${1:-"tms.local"}
SSL_TYPE=${2:-"self-signed"}

echo "Domain: $DOMAIN"
echo "SSL Type: $SSL_TYPE"

# Setup domain configuration
echo "🌐 Configuring domain..."
./scripts/configure-domain.sh $DOMAIN

# Setup SSL certificates
echo "🔒 Setting up SSL certificates..."
./scripts/setup-ssl.sh $DOMAIN $SSL_TYPE

# Check if .env exists
if [ ! -f .env ]; then
    echo "📝 Creating .env from production template..."
    cp .env.production .env
fi

# Run tests first
echo "🧪 Running tests..."
./scripts/run-tests.sh

if [ $? -ne 0 ]; then
    echo "❌ Tests failed. Deployment aborted."
    exit 1
fi

# Backup database
echo "💾 Creating database backup..."
./scripts/backup-db.sh

# Pull latest images
echo "📦 Pulling latest images..."
docker compose -f docker-compose.prod.yml pull

# Build and deploy
echo "🔨 Building and deploying..."
docker compose -f docker-compose.prod.yml up -d --build

# Wait for services
echo "⏳ Waiting for services to start..."
sleep 30

# Health check
echo "🏥 Running health checks..."
./scripts/health-check.sh

if [ $? -eq 0 ]; then
    echo "✅ Deployment successful!"
    echo "🌐 Application available at: https://$DOMAIN"
    echo "🔑 Admin login: admin@tms.com / password"
    echo "🚛 Driver login: driver1@tms.com / password"
    echo "🛠️  pgAdmin: https://$DOMAIN:5050"
else
    echo "❌ Health check failed. Rolling back..."
    docker compose -f docker-compose.prod.yml down
    exit 1
fi