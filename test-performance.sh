#!/bin/bash

echo "⚡ TMS Performance Test Suite"
echo "============================"

BASE_URL="http://localhost:8080"

# Test 1: API Response Time
echo "🧪 Testing API Response Times..."
echo "Testing /api/v1/ping..."
time curl -s "$BASE_URL/api/v1/ping" > /dev/null

echo "Testing /api/v1/db-status..."
time curl -s "$BASE_URL/api/v1/db-status" > /dev/null

echo "Testing /api/v1/vehicles..."
time curl -s "$BASE_URL/api/v1/vehicles" > /dev/null

# Test 2: Concurrent Requests
echo ""
echo "🧪 Testing Concurrent Requests (10 parallel)..."
for i in {1..10}; do
  curl -s "$BASE_URL/api/v1/ping" > /dev/null &
done
wait
echo "✅ Concurrent requests completed"

# Test 3: Database Connection Pool
echo ""
echo "🧪 Testing Database Connection Pool..."
for i in {1..5}; do
  echo "Request $i:"
  time curl -s "$BASE_URL/api/v1/db-status" | grep -o '"users_count":[0-9]*'
done

# Test 4: Memory Usage (if available)
echo ""
echo "🧪 Backend Container Memory Usage:"
docker stats tms-backend --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}" 2>/dev/null || echo "Container stats not available"

echo ""
echo "⚡ Performance Test Complete!"