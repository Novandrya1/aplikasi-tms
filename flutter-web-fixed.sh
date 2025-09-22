#!/bin/bash

echo "🌐 Starting Flutter Web with Backend"
echo "===================================="

# Ensure backend is running
echo "1. Checking backend status..."
if ! curl -s http://localhost:8080/health > /dev/null; then
    echo "Backend not running, starting..."
    make dev
    sleep 10
fi

# Test login
echo "2. Testing login..."
LOGIN_RESULT=$(curl -s -X POST http://localhost:8080/api/v1/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin@tms.com","password":"admin123"}')

if echo "$LOGIN_RESULT" | grep -q "token"; then
    echo "✅ Login working"
else
    echo "❌ Login failed: $LOGIN_RESULT"
    echo "Registering admin..."
    make register-admin
fi

# Clean up ports
echo "3. Cleaning up ports..."
sudo fuser -k 3005/tcp 2>/dev/null || true

# Start Flutter web
echo "4. Starting Flutter Web..."
echo "🚀 Flutter Web: http://localhost:3005"
echo "🔧 Backend API: http://localhost:8080"
echo "📋 Demo Login: admin@tms.com / admin123"
echo ""

cd frontend/aplikasi_tms
docker run --rm -p 3005:3005 \
  -v $(pwd):/app \
  -w /app \
  ghcr.io/cirruslabs/flutter:3.19.6 \
  sh -c "flutter pub get && flutter run -d web-server --web-port=3005 --web-hostname=0.0.0.0"