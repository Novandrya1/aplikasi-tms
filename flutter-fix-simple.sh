#!/bin/bash

echo "🔧 Flutter Fix & Run Script"
echo "=========================="

cd frontend/aplikasi_tms

# Install Flutter if not available
if ! command -v flutter &> /dev/null; then
    echo "Installing Flutter..."
    sudo snap install flutter --classic
    flutter config --enable-web
fi

echo "📦 Getting dependencies..."
flutter pub get

echo "🌐 Starting Flutter Web..."
flutter run -d web-server --web-port=3005 --web-hostname=0.0.0.0