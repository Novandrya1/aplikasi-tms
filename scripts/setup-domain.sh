#!/bin/bash

echo "🌐 Real Domain Setup"
echo "==================="

DOMAIN=${1:-"yourdomain.com"}
SERVER_IP=${2:-$(curl -s ifconfig.me)}

echo "Domain: $DOMAIN"
echo "Server IP: $SERVER_IP"

# Update DNS instructions
echo ""
echo "📋 DNS Configuration Required:"
echo "=============================="
echo "Add these DNS records to your domain:"
echo ""
echo "Type: A"
echo "Name: @"
echo "Value: $SERVER_IP"
echo "TTL: 300"
echo ""
echo "Type: A" 
echo "Name: www"
echo "Value: $SERVER_IP"
echo "TTL: 300"
echo ""

# Update production environment
cat > .env.prod << EOF
# Production Environment for $DOMAIN
DB_USER=tms_prod_user
DB_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
DB_NAME=tms_production
DB_SSLMODE=require
JWT_SECRET=$(openssl rand -base64 32)
ALLOWED_ORIGINS=https://$DOMAIN,https://www.$DOMAIN
DOMAIN=$DOMAIN
SERVER_IP=$SERVER_IP

# Security
CORS_ORIGINS=https://$DOMAIN,https://www.$DOMAIN
RATE_LIMIT=100

# Monitoring
LOG_LEVEL=info
ENABLE_METRICS=true

# Backup
BACKUP_RETENTION_DAYS=30
EOF

echo "✅ Production environment configured"
echo ""
echo "🔧 Next Steps:"
echo "1. Configure DNS records above"
echo "2. Wait for DNS propagation (5-30 minutes)"
echo "3. Run: ./scripts/setup-letsencrypt.sh $DOMAIN"
echo "4. Deploy: make deploy-prod DOMAIN=$DOMAIN"