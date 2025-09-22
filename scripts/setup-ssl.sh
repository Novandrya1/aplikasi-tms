#!/bin/bash

# SSL Certificate Setup Script
# Usage: ./setup-ssl.sh <domain> [self-signed|letsencrypt]
# Examples:
#   ./setup-ssl.sh tms.local self-signed
#   ./setup-ssl.sh yourdomain.com letsencrypt

show_usage() {
    echo "Usage: $0 <domain> [ssl-type]"
    echo "SSL Types:"
    echo "  self-signed  - Create self-signed certificate (development)"
    echo "  letsencrypt  - Use Let's Encrypt (production)"
    echo "Examples:"
    echo "  $0 tms.local self-signed"
    echo "  $0 yourdomain.com letsencrypt"
    exit 1
}

if [ "$1" = "--help" ] || [ "$1" = "-h" ] || [ -z "$1" ]; then
    show_usage
fi

echo "🔒 SSL Certificate Setup"
echo "======================="

DOMAIN=${1:-"tms.local"}
SSL_DIR="./ssl"

# Create SSL directory
mkdir -p $SSL_DIR

echo "Setting up SSL for domain: $DOMAIN"

# Option 1: Self-signed certificate (for development/testing)
if [ "$2" = "self-signed" ]; then
    echo "Creating self-signed certificate..."
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout $SSL_DIR/key.pem \
        -out $SSL_DIR/cert.pem \
        -subj "/C=ID/ST=Jakarta/L=Jakarta/O=TMS/OU=IT/CN=$DOMAIN"
    
    echo "✅ Self-signed certificate created"
    echo "⚠️  Remember to accept security warning in browser"
fi

# Option 2: Let's Encrypt (for production)
if [ "$2" = "letsencrypt" ]; then
    echo "Setting up Let's Encrypt certificate..."
    
    # Install certbot if not exists
    if ! command -v certbot &> /dev/null; then
        echo "Installing certbot..."
        sudo apt-get update
        sudo apt-get install -y certbot
    fi
    
    # Generate certificate
    sudo certbot certonly --standalone \
        --email admin@$DOMAIN \
        --agree-tos \
        --no-eff-email \
        -d $DOMAIN
    
    # Copy certificates
    sudo cp /etc/letsencrypt/live/$DOMAIN/fullchain.pem $SSL_DIR/cert.pem
    sudo cp /etc/letsencrypt/live/$DOMAIN/privkey.pem $SSL_DIR/key.pem
    sudo chown $USER:$USER $SSL_DIR/*.pem
    
    echo "✅ Let's Encrypt certificate created"
fi

# Set proper permissions
chmod 600 $SSL_DIR/key.pem
chmod 644 $SSL_DIR/cert.pem

echo "📁 SSL files created in: $SSL_DIR"
echo "🔑 Private key: $SSL_DIR/key.pem"
echo "📜 Certificate: $SSL_DIR/cert.pem"