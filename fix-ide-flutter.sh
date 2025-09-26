#!/bin/bash

echo "🔧 Memperbaiki masalah Flutter di IDE..."

cd /home/novandrya/aplikasi-tms/frontend/aplikasi_tms

echo "📦 Membuat symlink Flutter SDK untuk IDE..."

# Buat direktori flutter lokal jika belum ada
mkdir -p ~/.local/share/flutter

# Download Flutter SDK jika belum ada
if [ ! -d ~/.local/share/flutter/bin ]; then
    echo "📥 Downloading Flutter SDK..."
    cd ~/.local/share
    wget -q https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.3-stable.tar.xz
    tar xf flutter_linux_3.24.3-stable.tar.xz
    rm flutter_linux_3.24.3-stable.tar.xz
fi

# Tambahkan ke PATH
echo "🔗 Menambahkan Flutter ke PATH..."
if ! grep -q "flutter/bin" ~/.bashrc; then
    echo 'export PATH="$HOME/.local/share/flutter/bin:$PATH"' >> ~/.bashrc
fi

# Reload PATH
export PATH="$HOME/.local/share/flutter/bin:$PATH"

# Kembali ke direktori project
cd /home/novandrya/aplikasi-tms/frontend/aplikasi_tms

echo "🧪 Testing Flutter lokal..."
if ~/.local/share/flutter/bin/flutter --version; then
    echo "✅ Flutter lokal berhasil!"
    
    echo "📦 Menjalankan pub get..."
    ~/.local/share/flutter/bin/flutter pub get
    
    echo "🔍 Mengecek dependencies..."
    ~/.local/share/flutter/bin/flutter doctor
    
    echo "✅ Setup selesai!"
    echo ""
    echo "💡 Restart IDE Anda untuk menerapkan perubahan"
    echo "💡 Atau jalankan: source ~/.bashrc"
else
    echo "❌ Flutter lokal gagal"
    echo "💡 Gunakan Docker sebagai alternatif"
fi