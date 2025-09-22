#!/bin/bash

echo "🔍 TMS Authentication Debug Investigation"
echo "========================================"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "\n${BLUE}1. Database Connection Test${NC}"
DB_STATUS=$(curl -s http://localhost:8080/api/v1/db-status)
echo "DB Status: $DB_STATUS"

echo -e "\n${BLUE}2. Current Users in Database${NC}"
docker exec tms-postgres psql -U tms_user -d tms_db -c "SELECT id, username, email, role, created_at FROM users ORDER BY id;"

echo -e "\n${BLUE}3. Password Hash Analysis${NC}"
HASH=$(docker exec tms-postgres psql -U tms_user -d tms_db -t -c "SELECT password_hash FROM users WHERE username = 'admin';" | tr -d ' ')
echo "Current hash: $HASH"

echo -e "\n${BLUE}4. Test Registration with Debug${NC}"
REG_RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X POST http://localhost:8080/api/v1/register \
  -H "Content-Type: application/json" \
  -H "Origin: http://localhost:3006" \
  -d '{
    "username": "debuguser",
    "email": "debug@tms.com", 
    "password": "${DEBUG_PASSWORD:-debug123}",
    "full_name": "Debug User"
  }')
echo "Registration Response: $REG_RESPONSE"

echo -e "\n${BLUE}5. Test Login with Different Approaches${NC}"

# Test 1: Username
echo -e "\n${YELLOW}Test 1: Login with username${NC}"
LOGIN1=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X POST http://localhost:8080/api/v1/login \
  -H "Content-Type: application/json" \
  -H "Origin: http://localhost:3006" \
  -d '{
    "username": "admin",
    "password": "${ADMIN_PASSWORD:-admin123}"
  }')
echo "Response: $LOGIN1"

# Test 2: Email
echo -e "\n${YELLOW}Test 2: Login with email${NC}"
LOGIN2=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X POST http://localhost:8080/api/v1/login \
  -H "Content-Type: application/json" \
  -H "Origin: http://localhost:3006" \
  -d '{
    "username": "admin@tms.com",
    "password": "${ADMIN_PASSWORD:-admin123}"
  }')
echo "Response: $LOGIN2"

# Test 3: Debug user
echo -e "\n${YELLOW}Test 3: Login with debug user${NC}"
LOGIN3=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X POST http://localhost:8080/api/v1/login \
  -H "Content-Type: application/json" \
  -H "Origin: http://localhost:3006" \
  -d '{
    "username": "debuguser",
    "password": "${DEBUG_PASSWORD:-debug123}"
  }')
echo "Response: $LOGIN3"

echo -e "\n${BLUE}6. Backend Logs Analysis${NC}"
echo "Recent backend logs:"
docker logs tms-backend --tail 10

echo -e "\n${BLUE}7. Database Query Test${NC}"
echo "Testing direct database query for admin user:"
docker exec tms-postgres psql -U tms_user -d tms_db -c "
SELECT 
  id, username, email, 
  CASE WHEN password_hash IS NOT NULL THEN 'HASH_EXISTS' ELSE 'NO_HASH' END as hash_status,
  role, created_at 
FROM users 
WHERE username = 'admin' OR email = 'admin@tms.com';"

echo -e "\n${BLUE}8. Environment Variables Check${NC}"
echo "Checking if JWT_SECRET is set in container:"
docker exec tms-backend printenv | grep -E "(JWT|SECRET|GIN_MODE)" || echo "No JWT/SECRET env vars found"

echo -e "\n========================================"
echo -e "${GREEN}Investigation Complete${NC}"