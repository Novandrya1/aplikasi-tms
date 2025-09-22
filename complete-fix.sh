#!/bin/bash
set -e  # Exit on any error

# Cleanup function
cleanup() {
    echo "\n🧹 Cleaning up background processes..."
    if [ -n "$WEB_PID" ] && ps -p "$WEB_PID" > /dev/null 2>&1; then
        echo "Stopping web server (PID: $WEB_PID)..."
        kill "$WEB_PID" 2>/dev/null || true
    fi
}

# Set trap for cleanup
trap cleanup EXIT INT TERM

echo "🔧 Complete TMS Fix & Restart"
echo "============================="

# Stop all services
echo "1. Stopping all services..."
if ! docker compose down -v; then
    echo "❌ Failed to stop services"
    exit 1
fi

# Clean up
echo "2. Cleaning up..."
if ! docker system prune -f; then
    echo "⚠️ Cleanup failed, continuing..."
fi

# Build all services
echo "3. Building all services..."
if ! docker compose build --no-cache; then
    echo "❌ Failed to build services"
    exit 1
fi

# Start services
echo "4. Starting services..."
if ! docker compose up -d; then
    echo "❌ Failed to start services"
    exit 1
fi

# Wait for services
echo "5. Waiting for services to be ready..."
sleep 15

# Check status
echo "6. Checking service status..."
docker compose ps

# Test database
echo -e "\n7. Testing database connection..."
for i in {1..10}; do
  if curl -s http://localhost:8080/health > /dev/null; then
    echo "✅ Backend is ready"
    break
  else
    echo "⏳ Waiting for backend... ($i/10)"
    sleep 3
  fi
done

# Test web interface
echo -e "\n8. Testing web interface..."
echo "Starting web server..."
python3 -m http.server 3006 --bind 0.0.0.0 > /dev/null 2>&1 &
WEB_PID=$!
echo "Web server PID: $WEB_PID"
sleep 3
if curl -s -o /dev/null -w "%{http_code}" http://localhost:3006/tms-dashboard.html | grep -q "200"; then
    echo "✅ Web interface ready at http://localhost:3006/tms-dashboard.html"
else
    echo "❌ Web interface failed"
fi

# Register admin user
echo -e "\n9. Creating admin user..."
# Use environment variables for credentials in production
ADMIN_USER=${ADMIN_USER:-"admin"}
ADMIN_EMAIL=${ADMIN_EMAIL:-"admin@tms.com"}
ADMIN_PASS=${ADMIN_PASS:-"admin123"}

ADMIN_RESPONSE=$(curl -s -w "%{http_code}" -X POST http://localhost:8080/api/v1/register \
  -H "Content-Type: application/json" \
  -d "{
    \"username\": \"$ADMIN_USER\",
    \"email\": \"$ADMIN_EMAIL\",
    \"password\": \"$ADMIN_PASS\",
    \"full_name\": \"Administrator\",
    \"role\": \"admin\"
  }" 2>/dev/null)

if echo "$ADMIN_RESPONSE" | grep -q "201\|400"; then
    echo "✅ Admin user ready"
else
    echo "❌ Admin user creation failed: $ADMIN_RESPONSE"
    exit 1
fi

# Test login
echo -e "\n10. Testing authentication..."
LOGIN_RESPONSE=$(curl -s -X POST http://localhost:8080/api/v1/login \
  -H "Content-Type: application/json" \
  -d "{
    \"username\": \"$ADMIN_EMAIL\",
    \"password\": \"$ADMIN_PASS\"
  }")

if echo "$LOGIN_RESPONSE" | grep -q "token"; then
  echo "✅ Authentication working"
else
  echo "❌ Authentication failed"
  echo "Response: $LOGIN_RESPONSE"
fi

# Test vehicle API
echo -e "\n11. Testing vehicle API..."
VEHICLE_RESPONSE=$(curl -s http://localhost:8080/api/v1/vehicles)
if echo "$VEHICLE_RESPONSE" | grep -q "vehicles"; then
  echo "✅ Vehicle API working"
else
  echo "❌ Vehicle API failed"
  echo "Response: $VEHICLE_RESPONSE"
fi

echo -e "\n============================="
echo "🎉 Complete fix finished!"
echo ""
echo "🌐 Web Interface: http://localhost:3006/tms-dashboard.html"
echo "🔧 Backend API: http://localhost:8080"
echo "🗜️  Database Admin: http://localhost:5050"
echo ""
echo "👤 Login Credentials:"
echo "   Email: $ADMIN_EMAIL"
echo "   Password: [HIDDEN - check environment variables]"
echo ""
echo "📊 Service Status:"
if command -v docker &> /dev/null; then
    docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || docker compose ps
else
    echo "Docker not available"
fi