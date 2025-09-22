#!/bin/bash

echo "📱 Flutter Development Setup"

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter not installed. Installing via snap..."
    sudo snap install flutter --classic
    echo "✅ Flutter installed, configuring..."
    flutter config --enable-web
    flutter doctor
fi

# Navigate to Flutter project
if [ ! -d "frontend/aplikasi_tms" ]; then
    echo "❌ Flutter project directory not found"
    exit 1
fi

cd frontend/aplikasi_tms

# Get dependencies
echo "📦 Getting Flutter dependencies..."
flutter pub get

if ! flutter pub get; then
    echo "❌ Failed to get Flutter dependencies"
    exit 1
fi

# Check for available ports
echo "🔍 Checking available ports..."
FLUTTER_PORT_START=${FLUTTER_PORT_START:-3005}
FLUTTER_PORT_END=${FLUTTER_PORT_END:-3008}
FLUTTER_PORT=$FLUTTER_PORT_START
for port in $(seq "$FLUTTER_PORT_START" "$FLUTTER_PORT_END"); do
    if ! netstat -tuln | grep ":$port " &> /dev/null; then
        echo "✅ Port $port is available"
        FLUTTER_PORT="$port"
        break
    fi
done

echo "🚀 Starting Flutter Web on port $FLUTTER_PORT"
echo "🌐 Access at: http://localhost:$FLUTTER_PORT"
echo "🔧 Backend API: http://localhost:8080"
echo ""
echo "Press Ctrl+C to stop"

# Start Flutter web with better error handling
flutter run -d web-server --web-port=$FLUTTER_PORT --web-hostname=0.0.0.0 --web-renderer html