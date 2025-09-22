#!/bin/bash

echo "🌐 Starting Flutter Web..."

# Clean up any existing processes
pkill -f "flutter run" 2>/dev/null || true
pkill -f "http.server" 2>/dev/null || true

# Start backend first
echo "Starting backend..."
docker compose up -d postgres backend --build

# Wait for backend
sleep 10

# Run Flutter web directly with Docker
echo "Starting Flutter web on port 3005..."
docker run --rm -p 3005:3005 \
  -v $(pwd)/frontend/aplikasi_tms:/app \
  -w /app \
  ghcr.io/cirruslabs/flutter:3.19.6 \
  sh -c "flutter pub get && flutter run -d web-server --web-port=3005 --web-hostname=0.0.0.0"