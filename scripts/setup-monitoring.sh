#!/bin/bash

echo "📊 Production Monitoring Setup"
echo "=============================="

# Create logs directory
mkdir -p logs/{nginx,backend,frontend}

# Setup log rotation
sudo tee /etc/logrotate.d/tms << EOF
/home/$USER/aplikasi-tms/logs/*/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 644 $USER $USER
    postrotate
        docker compose restart nginx backend frontend
    endscript
}
EOF

# Create monitoring docker-compose
cat > docker-compose.monitoring.yml << EOF
services:
  prometheus:
    image: prom/prometheus:latest
    ports:
      - "9090:9090"
    volumes:
      - ./monitoring/prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'
    restart: unless-stopped

  grafana:
    image: grafana/grafana:latest
    ports:
      - "3001:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=${GRAFANA_ADMIN_PASSWORD:-admin123}
    volumes:
      - grafana_data:/var/lib/grafana
    restart: unless-stopped

volumes:
  prometheus_data:
  grafana_data:
EOF

# Create prometheus config
mkdir -p monitoring
cat > monitoring/prometheus.yml << EOF
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'tms-backend'
    static_configs:
      - targets: ['backend:8080']
    metrics_path: '/metrics'
    
  - job_name: 'tms-frontend'
    static_configs:
      - targets: ['frontend:80']
EOF

# Create health check cron
(crontab -l 2>/dev/null; echo "*/5 * * * * /home/$USER/aplikasi-tms/scripts/health-check.sh >> /home/$USER/aplikasi-tms/logs/health.log 2>&1") | crontab -

echo "✅ Monitoring setup complete"
echo ""
echo "📊 Access Points:"
echo "- Prometheus: http://localhost:9090"
echo "- Grafana: http://localhost:3001 (admin/admin123)"
echo "- Health checks: Every 5 minutes"
echo "- Log rotation: Daily, 30 days retention"