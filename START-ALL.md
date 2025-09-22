# 🚀 Cara Menjalankan Semua Server TMS

## Quick Start (Paling Mudah)

```bash
# 1. Masuk ke folder project
cd aplikasi-tms

# 2. Jalankan semua server sekaligus
make start
```

## Manual Docker Commands

```bash
# Start semua services
docker compose up -d

# Atau dengan rebuild
docker compose up -d --build
```

## Step by Step

```bash
# 1. Clone project (jika belum)
git clone <repository-url>
cd aplikasi-tms

# 2. Setup environment
cp .env.example .env

# 3. Start semua services
docker compose up -d --build

# 4. Tunggu services ready (30 detik)
sleep 30

# 5. Check status
./scripts/final-health.sh
```

## Akses Aplikasi

Setelah semua server jalan:

- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:8080  
- **pgAdmin**: http://localhost:5050
- **Login**: admin@tms.com / password

## Commands Berguna

```bash
# Status semua services
docker compose ps

# Logs semua services  
docker compose logs -f

# Stop semua services
docker compose down

# Restart service tertentu
docker compose restart backend
```

## Troubleshooting

Jika ada error:
```bash
# Clean restart
docker compose down -v
docker compose up -d --build
```