#!/bin/bash

echo "🔧 Memperbaiki masalah Flutter lokal..."

# Cek apakah Flutter snap terinstall
if ! snap list flutter &> /dev/null; then
    echo "❌ Flutter snap tidak terinstall"
    echo "💡 Solusi: Install Flutter dengan snap:"
    echo "   sudo snap install flutter --classic"
    exit 1
fi

echo "✅ Flutter snap terdeteksi"

# Cek versi Flutter
echo "📋 Informasi Flutter:"
snap info flutter

# Cek path Flutter
echo "📁 Path Flutter:"
which flutter
ls -la /snap/bin/flutter

# Cek permission
echo "🔐 Permission check:"
ls -la /snap/flutter/

# Coba jalankan Flutter dengan berbagai cara
echo "🧪 Testing Flutter commands..."

echo "1. Testing: flutter --version"
if flutter --version 2>/dev/null; then
    echo "✅ flutter --version berhasil"
else
    echo "❌ flutter --version gagal"
fi

echo "2. Testing: /snap/bin/flutter --version"
if /snap/bin/flutter --version 2>/dev/null; then
    echo "✅ /snap/bin/flutter --version berhasil"
else
    echo "❌ /snap/bin/flutter --version gagal"
fi

echo "3. Testing: snap run flutter --version"
if snap run flutter --version 2>/dev/null; then
    echo "✅ snap run flutter --version berhasil"
else
    echo "❌ snap run flutter --version gagal"
fi

# Masuk ke direktori project
cd /home/novandrya/aplikasi-tms/frontend/aplikasi_tms

echo "📦 Testing pub get..."
if flutter pub get 2>/dev/null; then
    echo "✅ flutter pub get berhasil"
else
    echo "❌ flutter pub get gagal"
    echo "💡 Mencoba dengan dart pub get..."
    if dart pub get 2>/dev/null; then
        echo "✅ dart pub get berhasil"
    else
        echo "❌ dart pub get juga gagal"
    fi
fi

echo "🏁 Diagnosis selesai"
echo ""
echo "💡 Solusi yang disarankan:"
echo "1. Gunakan Docker untuk development: ./fix-flutter-dev.sh"
echo "2. Atau gunakan Docker Compose: make frontend"
echo "3. Atau reinstall Flutter: sudo snap remove flutter && sudo snap install flutter --classic"