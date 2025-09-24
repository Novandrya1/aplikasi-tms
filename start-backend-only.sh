#!/bin/bash

echo "🚀 Starting Backend-Only TMS System..."

# 1. Stop all services
docker compose down

# 2. Build backend and database only
echo "Building backend services..."
docker compose build backend postgres

# 3. Start backend services
echo "Starting backend and database..."
docker compose up -d postgres backend

# 4. Wait for services
echo "Waiting for services to start..."
sleep 10

# 5. Run migrations
echo "Running database migrations..."
docker compose exec -T postgres psql -U tms_user -d tms_db -c "
-- Quick migration for testing
CREATE TABLE IF NOT EXISTS vehicles (
    id SERIAL PRIMARY KEY,
    registration_number VARCHAR(20) UNIQUE NOT NULL,
    vehicle_type VARCHAR(50) NOT NULL,
    brand VARCHAR(50) NOT NULL,
    model VARCHAR(50) NOT NULL,
    year INTEGER NOT NULL,
    chassis_number VARCHAR(50) UNIQUE NOT NULL,
    engine_number VARCHAR(50) NOT NULL,
    color VARCHAR(30) NOT NULL,
    capacity_weight DECIMAL(10,2),
    capacity_volume DECIMAL(10,2),
    ownership_status VARCHAR(20) NOT NULL,
    operational_status VARCHAR(20) DEFAULT 'active',
    verification_status VARCHAR(20) DEFAULT 'pending',
    verification_substatus VARCHAR(50),
    created_by INTEGER REFERENCES users(id),
    fleet_owner_id INTEGER,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS fleet_owners (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    company_name VARCHAR(255) NOT NULL,
    business_license VARCHAR(100),
    address TEXT NOT NULL,
    phone VARCHAR(20) NOT NULL,
    email VARCHAR(100) NOT NULL,
    owner_name VARCHAR(255),
    ktp_number VARCHAR(20),
    npwp VARCHAR(20),
    owner_type VARCHAR(20) DEFAULT 'individual',
    verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Insert sample data
INSERT INTO vehicles (registration_number, vehicle_type, brand, model, year, chassis_number, engine_number, color, capacity_weight, ownership_status, created_by, verification_status)
VALUES ('B 1234 TEST', 'Truk', 'Mitsubishi', 'Canter', 2022, 'CHASSIS123', 'ENGINE456', 'Putih', 3500.0, 'owned', 1, 'approved')
ON CONFLICT (registration_number) DO NOTHING;
"

# 6. Test API endpoints
echo "Testing API endpoints..."
echo "Health check:"
curl -s http://localhost:8080/health | jq . || echo "Health check failed"

echo -e "\nDatabase status:"
curl -s http://localhost:8080/api/v1/db-status | jq . || echo "DB check failed"

echo -e "\nAPI ping:"
curl -s http://localhost:8080/api/v1/ping | jq . || echo "Ping failed"

# 7. Show status
echo ""
echo "✅ Backend-Only TMS System is running!"
echo ""
echo "🔧 Backend API: http://localhost:8080"
echo "🗄️ Database: localhost:5432"
echo "📊 pgAdmin: http://localhost:5050"
echo ""
echo "🧪 Test API endpoints:"
echo "  curl http://localhost:8080/health"
echo "  curl http://localhost:8080/api/v1/ping"
echo "  curl http://localhost:8080/api/v1/db-status"
echo ""
echo "🔑 Login endpoint:"
echo '  curl -X POST http://localhost:8080/api/v1/login \'
echo '    -H "Content-Type: application/json" \'
echo '    -d '"'"'{"email":"admin@tms.com","password":"admin123"}'"'"
echo ""
echo "📋 Fleet registration endpoint:"
echo '  curl -X POST http://localhost:8080/api/v1/fleet/vehicles \'
echo '    -H "Authorization: Bearer YOUR_TOKEN" \'
echo '    -H "Content-Type: application/json" \'
echo '    -d '"'"'{"registration_number":"B 5678 NEW","vehicle_type":"Truk","brand":"Isuzu","model":"Elf","year":2023,"chassis_number":"CHASSIS789","engine_number":"ENGINE012","color":"Biru","ownership_status":"owned"}'"'"
echo ""
echo "Note: Frontend build skipped due to Flutter compilation issues"
echo "All backend functionality is available via API"