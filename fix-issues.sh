#!/bin/bash

echo "🔧 TMS Auto-Fix Script"
echo "======================"

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check port availability
check_port() {
    local port=$1
    if netstat -tuln | grep ":$port " >/dev/null 2>&1; then
        return 1  # Port is in use
    else
        return 0  # Port is available
    fi
}

echo "1. 🐳 Checking Docker services..."
if ! command_exists docker; then
    echo "❌ Docker not installed"
    exit 1
fi

if ! command_exists docker-compose; then
    echo "❌ Docker Compose not installed"
    exit 1
fi

echo "✅ Docker services available"

echo ""
echo "2. 🔄 Stopping existing containers..."
docker compose down

echo ""
echo "3. 🧹 Cleaning up..."
docker system prune -f

echo ""
echo "4. 🏗️ Rebuilding services..."
docker compose build --no-cache

echo ""
echo "5. 🚀 Starting services..."
docker compose up -d

echo ""
echo "6. ⏳ Waiting for services to be ready..."
WAIT_TIME=${WAIT_TIME:-15}
sleep "$WAIT_TIME"

echo ""
echo "7. 🧪 Testing services..."

# Test backend
if curl -s http://localhost:8080/health >/dev/null; then
    echo "✅ Backend: OK"
else
    echo "❌ Backend: Not responding"
fi

# Test database
if curl -s http://localhost:8080/api/v1/db-status >/dev/null; then
    echo "✅ Database: OK"
else
    echo "❌ Database: Not responding"
fi

echo ""
echo "8. 📱 Setting up Flutter..."

# Make flutter script executable
chmod +x flutter-dev.sh

# Check Flutter installation
if ! command_exists flutter; then
    echo "⚠️ Flutter not installed. Run 'make flutter-install' to install"
else
    echo "✅ Flutter: Available"
    cd frontend/aplikasi_tms
    flutter pub get
    cd ../..
fi

echo ""
echo "🎉 Fix completed!"
echo ""
echo "📋 Next steps:"
echo "  1. Backend: http://localhost:8080"
echo "  2. pgAdmin: http://localhost:5050"
echo "  3. Run 'make flutter-web' for frontend"
echo "  4. Run 'make test' to verify all services"