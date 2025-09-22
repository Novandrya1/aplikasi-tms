#!/bin/bash

echo "Testing TMS Application Connections..."
echo "======================================"

# Test Backend Health
echo "1. Testing Backend Health..."
curl -s http://localhost:8080/health | jq . || echo "Backend not responding"

# Test Database Connection
echo -e "\n2. Testing Database Connection..."
curl -s http://localhost:8080/api/v1/db-status | jq . || echo "Database connection failed"

# Test API Ping
echo -e "\n3. Testing API Ping..."
curl -s http://localhost:8080/api/v1/ping | jq . || echo "API ping failed"

# Test Frontend Health (through proxy)
echo -e "\n4. Testing Frontend Health..."
curl -s http://localhost:3000/health | jq . || echo "Frontend proxy not working"

# Test Vehicle API (through proxy)
echo -e "\n5. Testing Vehicle API..."
curl -s http://localhost:3000/api/v1/vehicles | jq . || echo "Vehicle API not accessible"

echo -e "\n======================================"
echo "Connection test completed!"