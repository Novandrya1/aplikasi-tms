#!/bin/bash

echo "🔌 API Integration Tests"
echo "======================="

BASE_URL="http://localhost:8080/api/v1"

# Test Health Check
echo "Testing Health Check..."
curl -s "$BASE_URL/health" | jq .

# Test Login
echo "Testing Login..."
LOGIN_RESPONSE=$(curl -s -X POST "$BASE_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@tms.com","password":"password"}')

TOKEN=$(echo $LOGIN_RESPONSE | jq -r '.token')
echo "Token: ${TOKEN:0:20}..."

# Test Protected Endpoint
echo "Testing Protected Endpoint..."
curl -s -H "Authorization: Bearer $TOKEN" "$BASE_URL/notifications" | jq .

# Test Fleet Endpoints
echo "Testing Fleet Endpoints..."
curl -s -H "Authorization: Bearer $TOKEN" "$BASE_URL/fleet/profile" | jq .

echo "✅ API tests completed!"