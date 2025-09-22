#!/bin/bash

set -e

echo "🏥 Simple Health Check"
echo "====================="

# Check if jq is available
if ! command -v jq >/dev/null 2>&1; then
    echo "❌ jq is required but not installed. Please install jq first."
    exit 1
fi

# Test backend
echo "Backend Health:"
curl -s http://localhost:8080/health | jq -r '.status' 2>/dev/null || echo "Failed"

# Test database
echo "Database Health:"
DB_RESULT=$(curl -s http://localhost:8080/api/v1/db-status 2>/dev/null)
if echo "$DB_RESULT" | grep -q '"status":"ok"'; then
    echo "OK"
else
    echo "Failed"
fi

# Test frontend
echo "Frontend Health:"
curl -s -I http://localhost:3000 | head -1 | grep -q "200 OK" && echo "OK" || echo "Failed"

echo ""
echo "🌐 Access URLs:"
echo "- Frontend: http://localhost:3000"
echo "- Backend: http://localhost:8080"
echo "- Admin: admin@tms.com / password"