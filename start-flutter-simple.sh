#!/bin/bash

echo "🚀 Starting Flutter Web TMS"
echo "==========================="

# Kill existing processes
sudo fuser -k 3007/tcp 3008/tcp 2>/dev/null || true

# Start CORS proxy in background
python3 proxy.py &
PROXY_PID=$!
echo "✅ CORS Proxy started (PID: $PROXY_PID)"

# Start Flutter web
echo "🌐 Starting Flutter Web on port 3008..."
cd frontend/aplikasi_tms
flutter pub get
flutter run -d web-server --web-port=3008 --web-hostname=0.0.0.0

# Cleanup on exit
kill $PROXY_PID 2>/dev/null || true