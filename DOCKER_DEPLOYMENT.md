# Docker Deployment - TMS Application

## 🐳 Docker Setup

Frontend Flutter telah dikonfigurasi untuk berjalan di Docker dengan Nginx sebagai web server dan reverse proxy.

## 🚀 Quick Start

### Using Makefile (Recommended)
```bash
# Build and start all services
make start

# Or step by step
make build
make up

# View status
make status
```

### Using Docker Compose
```bash
# Build all images
docker compose build

# Start all services
docker compose up -d

# View logs
docker compose logs -f
```

## 📦 Services

### Frontend (Port 3000)
- **Container**: `tms-frontend`
- **Technology**: Flutter Web + Nginx
- **Features**: 
  - Static file serving
  - API proxy to backend
  - Health checks

### Backend (Port 8080)
- **Container**: `tms-backend`
- **Technology**: Go + Gin
- **Features**:
  - REST API
  - JWT Authentication
  - Database integration

### Database (Port 5432)
- **Container**: `tms-postgres`
- **Technology**: PostgreSQL 15
- **Features**:
  - Persistent data storage
  - Health checks
  - Auto migrations

### pgAdmin (Port 5050)
- **Container**: `tms-pgadmin`
- **Technology**: pgAdmin 4
- **Access**: admin@tms.local / TMS_Admin_2024!

## 🔧 Makefile Commands

### Basic Operations
```bash
make help      # Show all commands
make build     # Build Docker images
make up        # Start all services
make down      # Stop all services
make restart   # Restart all services
make status    # Show service status
make logs      # View all logs
make clean     # Clean up everything
```

### Development
```bash
make dev       # Start backend + database only
make frontend  # Start frontend only
make backend   # Start backend only
make database  # Start database only
make test      # Test API endpoints
```

### Maintenance
```bash
make backup    # Backup database
make restore   # Restore database
make shell-backend   # Access backend container
make shell-database  # Access database
```

## 🌐 Access Points

After running `make up`:

- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:8080
- **pgAdmin**: http://localhost:5050
- **Database**: localhost:5432

## 🔍 Health Checks

All services include health checks:
- **Frontend**: HTTP check on port 80
- **Backend**: HTTP check on /health endpoint
- **Database**: PostgreSQL connection check

## 📊 Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend      │    │    Backend      │    │   Database      │
│   (Flutter)     │────│   (Go/Gin)      │────│  (PostgreSQL)   │
│   Port: 3000    │    │   Port: 8080    │    │   Port: 5432    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │    pgAdmin      │
                    │   Port: 5050    │
                    └─────────────────┘
```

## 🔧 Configuration

### Frontend Nginx Config
- Serves Flutter web build
- Proxies `/api/*` to backend
- Proxies `/health` to backend
- Handles SPA routing

### Environment Variables
```bash
# Database
DB_NAME=tms_db
DB_USER=tms_user
DB_PASSWORD=tms_password

# Backend
SERVER_PORT=8080
JWT_SECRET=your-jwt-secret
GIN_MODE=release

# pgAdmin
PGADMIN_EMAIL=admin@tms.local
PGADMIN_PASSWORD=TMS_Admin_2024!
```

## 🚀 Production Deployment

### 1. Environment Setup
```bash
# Copy environment template
cp .env.example .env

# Edit production values
nano .env
```

### 2. Build Production Images
```bash
make build
```

### 3. Start Services
```bash
make up
```

### 4. Verify Deployment
```bash
make test
make status
```

## 🔍 Troubleshooting

### Service Not Starting
```bash
# Check logs
make logs

# Check specific service
docker compose logs frontend
docker compose logs backend
docker compose logs postgres
```

### Build Issues
```bash
# Clean and rebuild
make clean
make build
```

### Database Issues
```bash
# Access database
make shell-database

# Check database status
curl http://localhost:8080/api/v1/db-status
```

### Frontend Issues
```bash
# Check if frontend is accessible
curl http://localhost:3000

# Check API proxy
curl http://localhost:3000/api/v1/ping
```

## 📈 Performance

### Frontend Optimizations
- Multi-stage Docker build
- Nginx static file serving
- Gzip compression
- Efficient caching

### Backend Optimizations
- Optimized Go binary
- Connection pooling
- Health checks
- Graceful shutdown

## 🔒 Security

### Production Considerations
- Change default passwords
- Use environment variables for secrets
- Enable HTTPS with SSL certificates
- Configure firewall rules
- Regular security updates

### Current Security Features
- JWT authentication
- CSRF protection
- Input validation
- SQL injection prevention
- XSS protection

## 📋 Demo Access

```
Frontend: http://localhost:3000
Login: admin@tms.com / admin123
```

All services are now containerized and ready for production deployment! 🐳