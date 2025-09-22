#!/bin/bash
set -e  # Exit on any error
set -u  # Exit on undefined variables

echo "🏥 Health Check"
echo "==============="

BASE_URL="http://localhost:8080"
FRONTEND_URL="http://localhost:3000"

# Check backend health
echo "Checking backend health..."
BACKEND_STATUS="$(curl -s --connect-timeout 5 --max-time 10 -o /dev/null -w "%{http_code}" "${BASE_URL}/health")"

if [ "${BACKEND_STATUS}" = "200" ]; then
    echo "✅ Backend is healthy"
else
    echo "❌ Backend health check failed (Status: ${BACKEND_STATUS})"
    exit 1
fi

# Check database connection
echo "Checking database connection..."
DB_RESPONSE="$(curl -s --connect-timeout 5 --max-time 10 "${BASE_URL}/api/v1/db-status" 2>/dev/null)"

if echo "${DB_RESPONSE}" | grep -q '"status":"ok"'; then
    echo "✅ Database is healthy"
else
    echo "❌ Database health check failed"
    echo "Response: ${DB_RESPONSE}"
    exit 1
fi

# Check frontend
echo "Checking frontend..."
FRONTEND_STATUS="$(curl -s --connect-timeout 5 --max-time 10 -o /dev/null -w "%{http_code}" "${FRONTEND_URL}")"

if [ "${FRONTEND_STATUS}" = "200" ]; then
    echo "✅ Frontend is healthy"
else
    echo "❌ Frontend health check failed (Status: ${FRONTEND_STATUS})"
    exit 1
fi

echo "✅ All services are healthy!"