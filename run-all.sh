#!/bin/bash
set -e  # Exit on any error

echo "🚀 Starting ALL TMS Services..."
echo "================================"

# 1. Start Backend Services
echo "1. Starting Backend + Database..."
if ! docker compose up -d postgres backend pgadmin; then
    echo "❌ Failed to start services"
    exit 1
fi

echo "2. Waiting for services..."
# Health check instead of fixed sleep
for i in {1..30}; do
    if curl -s http://localhost:8080/health > /dev/null 2>&1; then
        echo "✅ Backend is ready"
        break
    fi
    if [ "$i" -eq 30 ]; then
        echo "❌ Backend failed to start"
        exit 1
    fi
    sleep 1
done

# 2. Test Backend
echo "3. Testing backend..."
if ! make test; then
    echo "❌ Backend tests failed"
    exit 1
fi

# 3. Start Web Interface
echo "4. Starting Web Interface..."
echo "Starting simple web server on port 3006..."
nohup python3 -m http.server 3006 --bind 0.0.0.0 > web.log 2>&1 &
WEB_PID=$!
echo "$WEB_PID" > web.pid
echo "✅ Web interface started"

echo ""
echo "✅ TMS SERVICES RUNNING!"
echo "========================"
echo "🔧 Backend API: http://localhost:8080 ✅"
echo "🗄️ pgAdmin: http://localhost:5050 ✅"
echo "🌐 TMS Dashboard: http://localhost:3006/tms-dashboard.html ✅"
echo "📱 Mobile: Same URL works on mobile browser"
echo ""
echo "📋 Login: admin@tms.com / admin123"
echo "📝 Commands:"
echo "  make stop-all    - Stop all services"
echo "  make status      - Check status"
echo "  make test        - Test API endpoints"