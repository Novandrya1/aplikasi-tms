#!/bin/bash

echo "🔒 Let's Encrypt SSL Setup"
echo "=========================="

DOMAIN=${1:-"yourdomain.com"}
EMAIL=${2:-"admin@$DOMAIN"}

echo "Domain: $DOMAIN"
echo "Email: $EMAIL"

# Check if domain resolves to this server
echo "🔍 Checking DNS resolution..."
DOMAIN_IP=$(dig +short "$DOMAIN")
SERVER_IP=$(curl -s ifconfig.me)

if [ "$DOMAIN_IP" != "$SERVER_IP" ]; then
    echo "⚠️  Warning: Domain $DOMAIN resolves to $DOMAIN_IP but server IP is $SERVER_IP"
    echo "Please ensure DNS is properly configured before continuing."
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Stop nginx if running
docker compose down nginx 2>/dev/null || true

# Generate certificate
echo "📜 Generating SSL certificate..."
sudo certbot certonly --standalone \
    --email $EMAIL \
    --agree-tos \
    --no-eff-email \
    --domains "$DOMAIN","www.$DOMAIN"

if [ $? -eq 0 ]; then
    # Copy certificates
    sudo mkdir -p ssl
    sudo cp "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ssl/cert.pem
    sudo cp "/etc/letsencrypt/live/$DOMAIN/privkey.pem" ssl/key.pem
    sudo chown "$USER:$USER" ssl/*.pem
    chmod 600 ssl/key.pem
    chmod 644 ssl/cert.pem
    
    echo "✅ SSL certificate created successfully"
    
    # Setup auto-renewal
    echo "🔄 Setting up auto-renewal..."
    (crontab -l 2>/dev/null; echo "0 12 * * * /usr/bin/certbot renew --quiet --deploy-hook 'docker compose restart nginx'") | crontab -
    
    echo "✅ Auto-renewal configured"
else
    echo "❌ SSL certificate generation failed"
    exit 1
fi

echo ""
echo "🎉 SSL Setup Complete!"
echo "Certificate valid for: $DOMAIN, www.$DOMAIN"
echo "Auto-renewal: Configured (daily check at 12:00)"