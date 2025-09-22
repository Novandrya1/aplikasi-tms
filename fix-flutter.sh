#!/bin/bash

echo "🔧 Fixing Flutter SDK Issues..."

# Remove broken Flutter installation
echo "Removing current Flutter installation..."
sudo snap remove flutter 2>/dev/null || true

# Clean up any remaining Flutter files
echo "Cleaning up Flutter cache..."
rm -rf ~/.flutter* 2>/dev/null || true
rm -rf ~/.pub-cache 2>/dev/null || true

# Install Flutter fresh
echo "Installing Flutter SDK..."
sudo snap install flutter --classic

# Wait for installation
sleep 5

# Check Flutter path
echo "Checking Flutter installation..."
which flutter
flutter --version

# Accept licenses
echo "Accepting Android licenses..."
flutter doctor --android-licenses || true

# Run Flutter doctor
echo "Running Flutter doctor..."
flutter doctor

echo "✅ Flutter SDK fix complete!"