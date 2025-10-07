# Aplikasi TMS (Transport Management System)

Aplikasi manajemen transportasi dengan backend Go dan frontend Flutter yang fully containerized.

## Struktur Project

```
aplikasi-tms/
├── backend/                 # Go backend service
│   ├── cmd/server/         # Main application
│   ├── internal/           # Internal packages
│   └── Dockerfile          # Backend container
├── frontend/aplikasi_tms/  # Flutter frontend
│   ├── lib/                # Flutter source code
│   ├── Dockerfile          # Frontend container
│   └── nginx.conf          # Nginx configuration
├── migrations/             # Database migrations
├── docker-compose.yml      # Docker services
├── Makefile               # Build automation
├── .env.example           # Environment template
└── .env                   # Environment variables
```

## Services

- **Frontend**: Flutter Web + Nginx (Port 3000)
- **Backend**: Go REST API (Port 8080)
- **Database**: PostgreSQL 15 (Port 5432)
- **pgAdmin**: Database admin (Port 5050)

## 🚀 Quick Start

### Prerequisites
- Docker & Docker Compose
- Make (optional, for easier commands)

### 1. Clone & Setup
```bash
git clone <repository-url>
cd aplikasi-tms

# Copy environment template
cp .env.example .env
```

### 2. Start All Services
```bash
# Using Makefile (recommended)
make start

# Or using Docker Compose
docker compose up -d --build
```

### 3. Access Application
- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:8080
- **pgAdmin**: http://localhost:5050
- **Demo Login**: admin@tms.com / password

### 4. Verify Services
```bash
# Check status
make status

# Test API endpoints
make test

# View logs
make logs
```

## 🔄 Auto Commit

### Manual Auto Commit
```bash
# Commit semua perubahan sekali
./auto-commit.sh
```

### Auto Commit dengan Watcher
```bash
# Jalankan watcher untuk auto commit otomatis
./watch-and-commit.sh
```

## Database Schema

### Tables
- **users**: User management dengan role-based access
- **vehicles**: Data kendaraan dan status
- **drivers**: Data driver dengan lisensi
- **trips**: Perjalanan dengan tracking

### Environment Variables
```bash
# Copy dari template dan sesuaikan
cp .env.example .env

# Atau generate secrets otomatis
./generate-secrets.sh
```

## 🔒 Keamanan

### Setup Production
1. **Generate Secrets**: Jalankan `./generate-secrets.sh`
2. **Set Environment**: `export GIN_MODE=release`
3. **Database SSL**: Set `DB_SSLMODE=require` untuk production
4. **CORS Origins**: Update `ALLOWED_ORIGINS` dengan domain production

### Fitur Keamanan
- ✅ **CSRF Protection**: Aktif di production mode
- ✅ **Log Injection Prevention**: Semua input di-sanitasi
- ✅ **Safe Type Assertions**: Mencegah panic server
- ✅ **Database Connection Pooling**: Optimasi performa
- ✅ **JWT Authentication**: Token-based auth
- ✅ **Input Validation**: Validasi semua input user
- ✅ **Rate Limiting**: Pembatasan request per menit

## API Endpoints

### Health Check
- `GET /health` - Service health status

### API v1
- `GET /api/v1/ping` - API connectivity test
- `GET /api/v1/db-status` - Database connectivity and status

### Frontend
- `http://localhost:3000` - Flutter Web Dashboard
- All API endpoints accessible through frontend proxy

## 🔧 Development

### Using Makefile
```bash
make help      # Show all available commands
make dev       # Start backend + database only
make frontend  # Start frontend only
make backend   # Start backend only
make database  # Start database only
```

### Database Access
```bash
# Access database shell
make shell-database

# Backup database
make backup

# View specific logs
make logs-backend
make logs-frontend
make logs-database
```

### Stop Services
```bash
# Stop all services
make down

# Clean everything (containers, images, volumes)
make clean
```

## ✅ Completed Features

1. ✅ **Containerized Frontend**: Flutter Web + Nginx
2. ✅ **Backend Go service**: Gin framework dengan Docker
3. ✅ **PostgreSQL database**: Dengan health checks
4. ✅ **Full Docker setup**: Multi-container dengan networking
5. ✅ **Makefile automation**: Easy command management
6. ✅ **Frontend-Backend integration**: API proxy via Nginx
7. ✅ **Security hardening**: JWT, CSRF, input validation
8. ✅ **Health monitoring**: All services dengan health checks
9. ✅ **Development workflow**: Hot reload dan debugging
10. ✅ **Production ready**: Environment-based configuration

## 📋 Next Steps

- 🔐 Advanced authentication & authorization
- 📊 Enhanced dashboard dan reporting
- 🚀 Kubernetes deployment
- 📱 Mobile app deployment

## Troubleshooting

### Database Issues
```bash
# Reset database
docker compose down -v
docker compose up -d --build
```

### Backend Issues
```bash
# View backend logs
docker logs tms-backend

# Rebuild backend
docker compose build backend
docker compose up -d backend
```

### Frontend Issues
```bash
# View frontend logs
make logs-frontend

# Rebuild frontend
make build
make frontend

# Test frontend directly
curl http://localhost:3000
```

## 🐳 Docker Commands

### Quick Reference
```bash
# Build and start everything
make start

# View all services status
make status

# Follow all logs
make logs

# Stop everything
make down

# Clean up completely
make clean
```