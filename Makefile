.PHONY: help build up down logs clean test dev frontend backend database

# Default target
help:
	@echo "TMS - Transport Management System"
	@echo "================================="
	@echo "Available commands:"
	@echo "  make build     - Build all Docker images"
	@echo "  make up        - Start all services"
	@echo "  make down      - Stop all services"
	@echo "  make logs      - View all logs"
	@echo "  make clean     - Clean up containers and images"
	@echo "  make test      - Test API endpoints"
	@echo "  make dev       - Start backend + database only"
	@echo "  make frontend  - Start frontend only"
	@echo "  make backend   - Start backend only"
	@echo "  make database  - Start database only"

# Build all images
build:
	@echo "🔨 Building Docker images..."
	docker compose build

# Start all services
up:
	@echo "🚀 Starting all services..."
	docker compose up -d
	@echo "✅ Services started!"
	@echo "🌐 Frontend: http://localhost:3000"
	@echo "🔧 Backend: http://localhost:8080"
	@echo "🗄️ pgAdmin: http://localhost:5050"
	@echo "📋 Demo Login: admin@tms.com / admin123"

# Stop all services
down:
	@echo "🛑 Stopping all services..."
	docker compose down

# View logs
logs:
	docker compose logs -f

# Clean up
clean:
	@echo "🧹 Cleaning up..."
	docker compose down -v --rmi all --remove-orphans
	docker system prune -f

# Test API endpoints
test:
	@echo "🧪 Testing API endpoints..."
	@echo "Testing health endpoint..."
	curl -f http://localhost:8080/health || echo "❌ Health check failed"
	@echo "\nTesting ping endpoint..."
	curl -f http://localhost:8080/api/v1/ping || echo "❌ Ping failed"
	@echo "\nTesting database status..."
	curl -f http://localhost:8080/api/v1/db-status || echo "❌ Database check failed"

# Development mode (backend + database only)
dev:
	@echo "🔧 Starting development mode (backend + database)..."
	docker compose up -d postgres backend
	@echo "✅ Development services started!"
	@echo "🔧 Backend: http://localhost:8080"

# Start frontend only
frontend:
	@echo "🌐 Starting frontend..."
	docker compose up -d frontend

# Start backend only
backend:
	@echo "🔧 Starting backend..."
	docker compose up -d backend

# Start database only
database:
	@echo "🗄️ Starting database..."
	docker compose up -d postgres

# Quick start with build
start: build up

# Status check
status:
	@echo "📊 Service Status:"
	docker compose ps

# Restart all services
restart: down up

# View specific service logs
logs-backend:
	docker compose logs -f backend

logs-frontend:
	docker compose logs -f frontend

logs-database:
	docker compose logs -f postgres

# Execute commands in containers
shell-backend:
	docker compose exec backend sh

shell-database:
	docker compose exec postgres psql -U tms_user -d tms_db

# Backup database
backup:
	@echo "💾 Creating database backup..."
	docker compose exec postgres pg_dump -U tms_user tms_db > backup_$(shell date +%Y%m%d_%H%M%S).sql
	@echo "✅ Backup created!"

# Restore database
restore:
	@echo "📥 Restoring database..."
	@read -p "Enter backup file path: " file; \
	docker compose exec -T postgres psql -U tms_user -d tms_db < $$file
	@echo "✅ Database restored!"

# Testing commands
test-all:
	./scripts/run-tests.sh

test-backend:
	cd backend && go test ./... -v

test-frontend:
	cd frontend/aplikasi_tms && flutter test

test-api:
	./scripts/api-tests.sh

# Production deployment
deploy-prod:
	@echo "Usage: make deploy-prod DOMAIN=yourdomain.com SSL=letsencrypt"
	./scripts/deploy.sh $(DOMAIN) $(SSL)

setup-ssl:
	./scripts/setup-ssl.sh $(DOMAIN) $(SSL)

configure-domain:
	./scripts/configure-domain.sh $(DOMAIN) $(IP)

health-check:
	./scripts/health-check.sh

# Production services
prod-up:
	docker compose -f docker-compose.prod.yml up -d

prod-down:
	docker compose -f docker-compose.prod.yml down

prod-logs:
	docker compose -f docker-compose.prod.yml logs -f