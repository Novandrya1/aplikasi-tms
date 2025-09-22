#!/bin/bash

echo "🌐 Domain Configuration"
echo "======================"

DOMAIN=${1:-"tms.local"}
SERVER_IP=${2:-"127.0.0.1"}

echo "Configuring domain: $DOMAIN"
echo "Server IP: $SERVER_IP"

# Update production environment
cat > .env.production << EOF
# Production Environment - Updated $(date)
DB_USER=tms_prod_user
DB_PASSWORD=$(openssl rand -base64 32)
DB_NAME=tms_production
DB_SSLMODE=require

JWT_SECRET=$(openssl rand -base64 32)

# Domain Configuration
DOMAIN=$DOMAIN
SERVER_IP=$SERVER_IP
ALLOWED_ORIGINS=https://$DOMAIN,https://www.$DOMAIN

# SSL Configuration
SSL_CERT_PATH=/etc/nginx/ssl/cert.pem
SSL_KEY_PATH=/etc/nginx/ssl/key.pem

# Email Configuration
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=admin@$DOMAIN
SMTP_PASSWORD=your-app-password

# File Upload
MAX_FILE_SIZE=10485760
UPLOAD_PATH=/app/uploads

# Redis
REDIS_URL=redis://redis:6379

# Monitoring
LOG_LEVEL=info
ENABLE_METRICS=true

# Backup
BACKUP_SCHEDULE=0 2 * * *
BACKUP_RETENTION_DAYS=30
EOF

echo "✅ Environment configured for $DOMAIN"

# Update nginx configuration
cat > nginx/nginx.prod.conf << EOF
# Production Nginx Configuration for $DOMAIN
upstream backend {
    server backend:8080;
}

# HTTP to HTTPS redirect
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;
    return 301 https://\$server_name\$request_uri;
}

# HTTPS server
server {
    listen 443 ssl http2;
    server_name $DOMAIN www.$DOMAIN;
    
    # SSL Configuration
    ssl_certificate /etc/nginx/ssl/cert.pem;
    ssl_certificate_key /etc/nginx/ssl/key.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    
    # Security headers
    add_header Strict-Transport-Security "max-age=63072000" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    
    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
    
    # Frontend
    location / {
        root /usr/share/nginx/html;
        index index.html;
        try_files \$uri \$uri/ /index.html;
    }
    
    # API proxy
    location /api/ {
        proxy_pass http://backend;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # CORS
        add_header Access-Control-Allow-Origin "https://$DOMAIN" always;
        add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
        add_header Access-Control-Allow-Headers "Authorization, Content-Type" always;
        
        if (\$request_method = 'OPTIONS') {
            return 204;
        }
    }
    
    # Static files caching
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
EOF

mkdir -p nginx
echo "✅ Nginx configuration created for $DOMAIN"

# Update hosts file for local testing
if [ "$SERVER_IP" = "127.0.0.1" ]; then
    echo "Adding $DOMAIN to /etc/hosts for local testing..."
    echo "$SERVER_IP $DOMAIN" | sudo tee -a /etc/hosts
    echo "✅ Local hosts file updated"
fi

echo "🎯 Domain configuration complete!"
echo "📝 Next steps:"
echo "1. Point DNS A record: $DOMAIN -> $SERVER_IP"
echo "2. Setup SSL certificate: ./scripts/setup-ssl.sh $DOMAIN letsencrypt"
echo "3. Deploy: make deploy-prod"