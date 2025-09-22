#!/bin/bash

set -e

echo "🧪 Running TMS Test Suite"
echo "========================="

# Backend Tests
echo "📦 Running Backend Tests..."
if ! cd backend; then
    echo "❌ Failed to change to backend directory"
    exit 1
fi

echo "  → Unit Tests"
go test ./internal/services/... -v

echo "  → Integration Tests"
go test ./tests/... -v

echo "  → Test Coverage"
go test -coverprofile=coverage.out ./...
go tool cover -html=coverage.out -o coverage.html

if ! cd ..; then
    echo "❌ Failed to return to root directory"
    exit 1
fi

# Frontend Tests
echo "🎨 Running Frontend Tests..."
if ! cd frontend/aplikasi_tms; then
    echo "❌ Failed to change to frontend directory"
    exit 1
fi

echo "  → Unit Tests"
flutter test

if ! cd ../..; then
    echo "❌ Failed to return to root directory"
    exit 1
fi

# API Tests
echo "🌐 Running API Tests..."
./scripts/api-tests.sh

echo "✅ All tests completed!"