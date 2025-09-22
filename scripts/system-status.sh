#!/bin/bash

echo "🚀 TMS System Status Dashboard"
echo "=============================="

# Service Status
echo "📊 Service Status:"
docker compose ps --format "table {{.Service}}\t{{.Status}}\t{{.Ports}}"

echo -e "\n🔗 Connectivity Tests:"

# Backend Health
BACKEND_STATUS=$(curl -s --max-time 5 -w "%{http_code}" -o /dev/null http://localhost:8080/health)
if [ "$BACKEND_STATUS" = "200" ]; then
    echo "✅ Backend API (Port 8080)"
else
    echo "❌ Backend API (Status: $BACKEND_STATUS)"
fi

# Database Health
DB_STATUS=$(curl -s --max-time 5 -w "%{http_code}" -o /dev/null http://localhost:8080/api/v1/db-status)
if [ "$DB_STATUS" = "200" ]; then
    echo "✅ Database Connection"
else
    echo "❌ Database Connection (Status: $DB_STATUS)"
fi

# Frontend Health
FRONTEND_STATUS=$(curl -s --max-time 5 -w "%{http_code}" -o /dev/null http://localhost:3000)
if [ "$FRONTEND_STATUS" = "200" ]; then
    echo "✅ Frontend Web (Port 3000)"
else
    echo "❌ Frontend Web (Status: $FRONTEND_STATUS)"
fi

# pgAdmin Health
PGADMIN_STATUS=$(curl -s --max-time 5 -w "%{http_code}" -o /dev/null http://localhost:5050)
if [ "$PGADMIN_STATUS" = "200" ]; then
    echo "✅ pgAdmin (Port 5050)"
else
    echo "❌ pgAdmin (Status: $PGADMIN_STATUS)"
fi

echo -e "\n📋 Database Info:"
USER_COUNT=$(docker exec tms-postgres psql -U tms_user -d tms_db -t -c "SELECT COUNT(*) FROM users;" 2>/dev/null | tr -d ' ')
VEHICLE_COUNT=$(docker exec tms-postgres psql -U tms_user -d tms_db -t -c "SELECT COUNT(*) FROM vehicles;" 2>/dev/null | tr -d ' ')
TRIP_COUNT=$(docker exec tms-postgres psql -U tms_user -d tms_db -t -c "SELECT COUNT(*) FROM trips;" 2>/dev/null | tr -d ' ')

echo "- Users: ${USER_COUNT:-0}"
echo "- Vehicles: ${VEHICLE_COUNT:-0}"
echo "- Trips: ${TRIP_COUNT:-0}"

echo -e "\n🌐 Access URLs:"
echo "- Frontend: http://localhost:3000"
echo "- Backend API: http://localhost:8080"
echo "- API Docs: http://localhost:8080/api/v1/ping"
echo "- pgAdmin: http://localhost:5050"

echo -e "\n🔑 Test Accounts:"
echo "- Admin: admin@tms.com / password"
echo "- Driver: driver1@tms.com / password"

echo -e "\n📱 Available Features:"
echo "- ✅ User Authentication (Admin, Fleet Owner, Driver)"
echo "- ✅ Fleet Management (Registration, Vehicles)"
echo "- ✅ File Upload System (Documents, Photos)"
echo "- ✅ Admin Panel (Vehicle Verification)"
echo "- ✅ Enhanced Dashboard (Notifications, Analytics)"
echo "- ✅ Driver Mobile App (Trip Management, GPS Tracking)"
echo "- ✅ Testing & Deployment Setup"

echo -e "\n🚀 Quick Commands:"
echo "- make start     # Start all services"
echo "- make test      # Run API tests"
echo "- make logs      # View logs"
echo "- make clean     # Clean up"