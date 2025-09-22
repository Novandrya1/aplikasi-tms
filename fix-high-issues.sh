#!/bin/bash
set -e

echo "🔧 Fixing High Priority Security Issues..."

# Restart backend with fixes
echo "Restarting backend..."
if ! docker compose restart backend; then
    echo "❌ Failed to restart backend"
    exit 1
fi

# Wait for backend to be ready
echo "⏳ Waiting for backend..."
for i in {1..30}; do
    if curl -s http://localhost:8080/health > /dev/null 2>&1; then
        echo "✅ Backend ready"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "❌ Backend timeout"
        exit 1
    fi
    sleep 1
done

# Test security fixes
echo "Testing security fixes..."
if ! make test-security; then
    echo "❌ Security tests failed"
    exit 1
fi

echo "✅ High priority issues fixed!"