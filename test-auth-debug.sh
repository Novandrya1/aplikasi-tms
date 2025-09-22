#!/bin/bash

echo "🔐 Testing Authentication Debug..."
echo "=================================="

# Test 1: Register a test user
echo "1. Registering test user..."
REGISTER_RESPONSE=$(curl -s -X POST http://localhost:3000/api/v1/register \
  -H "Content-Type: application/json" \
  -H "Origin: http://localhost:3000" \
  -d '{
    "username": "testuser",
    "email": "test@example.com", 
    "password": "test123",
    "full_name": "Test User"
  }')

echo "Register Response: $REGISTER_RESPONSE"

# Test 2: Login with username
echo -e "\n2. Testing login with username..."
LOGIN_USERNAME_RESPONSE=$(curl -s -X POST http://localhost:3000/api/v1/login \
  -H "Content-Type: application/json" \
  -H "Origin: http://localhost:3000" \
  -d '{
    "username": "testuser",
    "password": "test123"
  }')

echo "Login with Username Response: $LOGIN_USERNAME_RESPONSE"

# Test 3: Login with email
echo -e "\n3. Testing login with email..."
LOGIN_EMAIL_RESPONSE=$(curl -s -X POST http://localhost:3000/api/v1/login \
  -H "Content-Type: application/json" \
  -H "Origin: http://localhost:3000" \
  -d '{
    "username": "test@example.com",
    "password": "test123"
  }')

echo "Login with Email Response: $LOGIN_EMAIL_RESPONSE"

# Test 4: Check database users
echo -e "\n4. Checking database status..."
DB_STATUS=$(curl -s http://localhost:3000/api/v1/db-status)
echo "Database Status: $DB_STATUS"

# Test 5: Wrong password
echo -e "\n5. Testing wrong password..."
WRONG_PASSWORD_RESPONSE=$(curl -s -X POST http://localhost:3000/api/v1/login \
  -H "Content-Type: application/json" \
  -H "Origin: http://localhost:3000" \
  -d '{
    "username": "test@example.com",
    "password": "wrongpassword"
  }')

echo "Wrong Password Response: $WRONG_PASSWORD_RESPONSE"

echo -e "\n=================================="
echo "Authentication debug test completed!"