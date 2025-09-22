#!/bin/bash

echo "🌐 Starting Flutter Web Application"
echo "=================================="

# Clean up
echo "1. Cleaning up existing processes..."
sudo fuser -k 3005/tcp 2>/dev/null || true
docker stop $(docker ps -q) 2>/dev/null || true

# Start backend
echo "2. Starting backend services..."
docker compose up -d postgres backend --build

# Wait for backend
echo "3. Waiting for backend to be ready..."
sleep 10

# Test backend
echo "4. Testing backend connection..."
if curl -s http://localhost:8080/health > /dev/null; then
    echo "✅ Backend is ready"
else
    echo "❌ Backend not ready"
    exit 1
fi

# Start Flutter web
echo "5. Starting Flutter Web..."
echo "🚀 Flutter Web will be available at: http://localhost:3005"
echo "🔧 Backend API: http://localhost:8080"
echo "📋 Demo Login: admin@tms.com / admin123"
echo ""

docker run --rm -p 3005:3005 \
  -v $(pwd)/frontend/aplikasi_tms:/app \
  -w /app \
  ghcr.io/cirruslabs/flutter:3.19.6 \
  sh -c "flutter pub get && flutter run -d web-server --web-port=3005 --web-hostname=0.0.0.0"