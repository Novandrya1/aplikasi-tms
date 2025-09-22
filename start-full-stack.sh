#!/bin/bash
set -e

# Cleanup function
cleanup() {
    echo "\n🧹 Cleaning up background processes..."
    if [ -f "frontend/aplikasi_tms/flutter_web.pid" ]; then
        FLUTTER_PID=$(cat frontend/aplikasi_tms/flutter_web.pid)
        if ps -p "$FLUTTER_PID" > /dev/null 2>&1; then
            echo "Stopping Flutter web (PID: $FLUTTER_PID)..."
            kill "$FLUTTER_PID" 2>/dev/null || true
        fi
        rm -f frontend/aplikasi_tms/flutter_web.pid
    fi
}

# Set trap for cleanup on script exit
trap cleanup EXIT INT TERM

echo "🚀 Starting Full Stack TMS Application"
echo "======================================"

# Check if required tools are installed
command -v docker >/dev/null 2>&1 || { echo "❌ Docker is required but not installed."; exit 1; }
command -v flutter >/dev/null 2>&1 || { echo "❌ Flutter is required but not installed."; exit 1; }

# 1. Start Backend Services
echo "1. Starting Backend + Database..."
if ! docker compose up -d postgres backend; then
    echo "❌ Failed to start backend services"
    exit 1
fi

# 2. Wait for backend to be ready
echo "2. Waiting for backend to be ready..."
for i in {1..30}; do
    if curl -s http://localhost:8080/health > /dev/null 2>&1; then
        echo "✅ Backend is ready"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "❌ Backend failed to start"
        exit 1
    fi
    sleep 2
done

# 3. Test backend connection
echo "3. Testing backend connection..."
if curl -s http://localhost:8080/api/v1/ping | grep -q "pong"; then
    echo "✅ Backend API is responding"
else
    echo "❌ Backend API is not responding"
    exit 1
fi

# 4. Test database connection
echo "4. Testing database connection..."
if curl -s http://localhost:8080/api/v1/db-status | grep -q "ok"; then
    echo "✅ Database is connected"
else
    echo "❌ Database connection failed"
    exit 1
fi

# 5. Start Flutter Web
echo "5. Starting Flutter Web..."
cd frontend/aplikasi_tms

# Install dependencies if needed
if [ ! -d ".dart_tool" ]; then
    echo "Installing Flutter dependencies..."
    flutter pub get
fi

# Start Flutter web in background
echo "Starting Flutter web on port 3000..."
nohup flutter run -d web-server --web-port 3000 --web-hostname 0.0.0.0 > flutter_web.log 2>&1 &
FLUTTER_PID=$!
echo "$FLUTTER_PID" > flutter_web.pid

# Wait for Flutter web to start
echo "Waiting for Flutter web to start..."
for i in {1..20}; do
    if curl -s http://localhost:3000 > /dev/null 2>&1; then
        echo "✅ Flutter web is ready"
        break
    fi
    if [ $i -eq 20 ]; then
        echo "⚠️ Flutter web may still be starting..."
        break
    fi
    sleep 3
done

cd ../..

echo ""
echo "🎉 FULL STACK TMS IS RUNNING!"
echo "============================="
echo "🔧 Backend API: http://localhost:8080"
echo "🗄️ Database: PostgreSQL on port 5432"
echo "🌐 Flutter Web: http://localhost:3000"
echo "📱 Mobile: Use same URL on mobile browser"
echo ""
echo "📋 Demo Login:"
echo "  Email: admin@tms.com"
echo "  Password: admin123"
echo ""
echo "📝 Commands:"
echo "  ./stop-full-stack.sh  - Stop all services"
echo "  docker logs tms-backend - View backend logs"
echo "  tail -f frontend/aplikasi_tms/flutter_web.log - View Flutter logs"
echo ""
echo "🔍 Test Connection: Click the WiFi icon in the app"