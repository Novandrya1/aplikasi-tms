#!/bin/bash

set -e  # Exit on any error

echo "🔧 Fixing All Critical & High Issues"
echo "===================================="

# Restart backend to apply Go fixes
echo "1. Restarting backend..."
if ! docker compose restart backend; then
    echo "❌ Failed to restart backend"
    exit 1
fi
sleep 5

# Test security after fixes
echo "2. Testing security..."
if ! make test-security; then
    echo "❌ Security tests failed"
    exit 1
fi

# Test all endpoints
echo "3. Testing all endpoints..."
if ! make test-all-endpoints; then
    echo "❌ Endpoint tests failed"
    exit 1
fi

echo "✅ All critical and high issues fixed!"