#!/bin/bash

echo "🚀 Complete Production Deployment"
echo "================================="

DOMAIN=${1:-"tms.local"}
EMAIL=${2:-"admin@$DOMAIN"}

echo "Domain: $DOMAIN"
echo "Email: $EMAIL"

# Step 1: Setup domain configuration
echo "🌐 Step 1: Domain Configuration"
./scripts/setup-domain.sh $DOMAIN

# Step 2: Setup SSL (Let's Encrypt or self-signed)
echo "🔒 Step 2: SSL Setup"
if [ "$DOMAIN" = "tms.local" ] || [ "$DOMAIN" = "localhost" ]; then
    echo "Using self-signed certificate for local domain"
    ./scripts/setup-ssl.sh $DOMAIN self-signed
else
    echo "Using Let's Encrypt for production domain"
    ./scripts/setup-letsencrypt.sh $DOMAIN $EMAIL
fi

# Step 3: Setup monitoring
echo "📊 Step 3: Monitoring Setup"
./scripts/setup-monitoring.sh

# Step 4: Create production environment
echo "⚙️  Step 4: Environment Setup"
cp .env.prod .env

# Step 5: Deploy services
echo "🚀 Step 5: Service Deployment"
docker compose -f docker-compose.yml up -d --build

# Step 6: Wait and health check
echo "⏳ Step 6: Health Verification"
sleep 30
./scripts/health-check.sh

echo ""
echo "🎉 Production Deployment Complete!"
echo "=================================="
echo "🌐 Frontend: https://$DOMAIN"
echo "🔧 Backend: https://$DOMAIN/api"
echo "📊 Monitoring: http://localhost:9090 (Prometheus)"
echo "📈 Grafana: http://localhost:3001"
echo ""
echo "🔑 Login Credentials:"
echo "- Admin: admin@tms.com / password"
echo "- Driver: driver1@tms.com / password"
echo "- Grafana: admin / admin123"