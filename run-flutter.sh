#!/bin/bash

echo "🚀 Starting Flutter Mobile Development"
echo "======================================"

cd frontend/aplikasi_tms

# Check if Flutter is available
if command -v flutter &> /dev/null; then
    echo "✅ Flutter found: $(flutter --version | head -1)"
    
    echo "📦 Getting dependencies..."
    flutter pub get
    
    echo "📱 Available devices:"
    flutter devices
    
    echo ""
    echo "🎯 Choose how to run:"
    echo "1. Mobile (if device/emulator available)"
    echo "2. Web (browser)"
    echo "3. Desktop (Linux)"
    
    read -p "Enter choice (1-3): " choice
    
    case $choice in
        1)
            echo "🚀 Starting mobile app..."
            flutter run
            ;;
        2)
            echo "🌐 Starting web app on http://localhost:3002..."
            flutter run -d web-server --web-port=3002 --web-hostname=0.0.0.0
            ;;
        3)
            echo "🖥️ Starting desktop app..."
            flutter run -d linux
            ;;
        *)
            echo "❌ Invalid choice"
            ;;
    esac
else
    echo "❌ Flutter not found!"
    echo "📋 Available options:"
    echo "1. Install Flutter: https://docs.flutter.dev/get-started/install"
    echo "2. Use Docker container (if available)"
    echo "3. Use test interface: http://localhost:3001/test-interface.html"
fi