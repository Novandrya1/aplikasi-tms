#!/bin/bash

set -e  # Exit on any error

echo "🔧 FIXING FLUTTER PROJECT"
echo "========================="

if ! cd frontend/aplikasi_tms; then
    echo "❌ Failed to change to Flutter directory"
    exit 1
fi

# Fix API service for web and mobile
echo "📱 Fixing API services for cross-platform..."

# Create config for different platforms
cat > lib/config/api_config.dart << 'EOF'
class ApiConfig {
  static const String _webBaseUrl = 'http://localhost:8080/api/v1';
  static const String _mobileBaseUrl = 'http://10.0.2.2:8080/api/v1'; // Android emulator
  
  static String get baseUrl {
    // For web platform
    if (identical(0, 0.0)) {
      return _webBaseUrl;
    }
    // For mobile platforms
    return _mobileBaseUrl;
  }
  
  static String get healthUrl {
    if (identical(0, 0.0)) {
      return 'http://localhost:8080/health';
    }
    return 'http://10.0.2.2:8080/health';
  }
}
EOF

echo "✅ API config created"

# Test Flutter project
echo "🧪 Testing Flutter project..."
docker run --rm -v $(pwd):/app -w /app ghcr.io/cirruslabs/flutter:3.19.6 sh -c "
  echo '📦 Getting dependencies...'
  flutter pub get
  echo '🔍 Analyzing project...'
  flutter analyze --no-fatal-infos
  echo '✅ Flutter project ready'
"

echo "🚀 Flutter project fixed and ready!"
echo "📱 Run: make flutter-web (for web)"
echo "📱 Run: ./flutter-dev.sh (for development)"