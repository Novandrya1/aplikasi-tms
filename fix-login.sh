#!/bin/bash

echo "🔧 Fixing Login Issues..."
echo "========================="

# Stop all services
echo "1. Stopping all services..."
docker compose down

# Start services with fresh build
echo "2. Starting services with fresh build..."
docker compose up -d --build

# Wait for services to be ready
echo "3. Waiting for services to be ready..."
sleep 10

# Check if services are running
echo "4. Checking service status..."
docker compose ps

# Test database connection
echo -e "\n5. Testing database connection..."
for i in {1..5}; do
  if curl -s http://localhost:3000/api/v1/db-status > /dev/null; then
    echo "✅ Database connected"
    break
  else
    echo "⏳ Waiting for database... ($i/5)"
    sleep 5
  fi
done

# Register admin user
echo -e "\n6. Registering admin user..."
curl -s -X POST http://localhost:3000/api/v1/register \
  -H "Content-Type: application/json" \
  -H "Origin: http://localhost:3000" \
  -d '{
    "username": "admin",
    "email": "admin@tms.com",
    "password": "admin123",
    "full_name": "Administrator",
    "role": "admin"
  }' && echo " ✅ Admin user created"

# Test login
echo -e "\n7. Testing login..."
LOGIN_RESPONSE=$(curl -s -X POST http://localhost:3000/api/v1/login \
  -H "Content-Type: application/json" \
  -H "Origin: http://localhost:3000" \
  -d '{
    "username": "admin@tms.com",
    "password": "admin123"
  }')

if echo "$LOGIN_RESPONSE" | grep -q "token"; then
  echo "✅ Login test successful"
else
  echo "❌ Login test failed: $LOGIN_RESPONSE"
fi

echo -e "\n========================="
echo "🎉 Login fix completed!"
echo ""
echo "📱 Frontend: http://localhost:3000"
echo "👤 Test Account:"
echo "   Email: admin@tms.com"
echo "   Password: admin123"
echo ""
echo "🔍 Run './test-auth-debug.sh' for detailed testing"