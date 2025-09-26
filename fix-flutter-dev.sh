#!/bin/bash

echo "🔧 Memperbaiki masalah Flutter development..."

# Masuk ke direktori frontend
cd /home/novandrya/aplikasi-tms/frontend/aplikasi_tms

echo "📦 Menggunakan Docker untuk Flutter development..."

# Buat Dockerfile untuk development
cat > Dockerfile.dev << 'EOF'
FROM ghcr.io/cirruslabs/flutter:stable

WORKDIR /app
COPY pubspec.* ./
RUN flutter pub get

COPY . .

# Expose port untuk hot reload
EXPOSE 3000

# Command untuk development
CMD ["flutter", "run", "-d", "web-server", "--web-hostname", "0.0.0.0", "--web-port", "3000"]
EOF

echo "🐳 Membuat container Flutter development..."
docker build -f Dockerfile.dev -t flutter-dev .

echo "🚀 Menjalankan Flutter development server..."
echo "Frontend akan tersedia di: http://localhost:3000"
echo "Tekan Ctrl+C untuk menghentikan"

docker run -it --rm \
  -p 3000:3000 \
  -v $(pwd):/app \
  -v /app/.dart_tool \
  flutter-dev

echo "✅ Flutter development server selesai"