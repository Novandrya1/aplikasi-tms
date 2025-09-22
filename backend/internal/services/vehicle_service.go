package services

import (
	"database/sql"
	"fmt"
	"log"
	"time"

	"github.com/youruser/aplikasi-tms/backend/internal/middleware"
	"github.com/youruser/aplikasi-tms/backend/internal/models"
)

func CreateVehicle(db *sql.DB, req models.VehicleRequest, userID int) (*models.Vehicle, error) {
	// Check if registration number already exists
	var exists bool
	checkQuery := "SELECT EXISTS(SELECT 1 FROM vehicles WHERE registration_number = $1 OR chassis_number = $2)"
	err := db.QueryRow(checkQuery, req.RegistrationNumber, req.ChassisNumber).Scan(&exists)
	if err != nil {
		return nil, fmt.Errorf("failed to check vehicle existence: %v", err)
	}
	if exists {
		return nil, fmt.Errorf("vehicle with registration number or chassis number already exists")
	}

	// Parse dates with proper error handling
	insuranceExpiry, err := parseOptionalDate(req.InsuranceExpiryDate, "insurance expiry")
	if err != nil {
		return nil, err
	}
	lastMaintenance, err := parseOptionalDate(req.LastMaintenanceDate, "last maintenance")
	if err != nil {
		return nil, err
	}
	nextMaintenance, err := parseOptionalDate(req.NextMaintenanceDate, "next maintenance")
	if err != nil {
		return nil, err
	}

	// Set default operational status
	operationalStatus := req.OperationalStatus
	if operationalStatus == "" {
		operationalStatus = "active"
	}

	query := `INSERT INTO vehicles (
		registration_number, vehicle_type, brand, model, year,
		chassis_number, engine_number, color, capacity_weight, capacity_volume,
		ownership_status, operational_status, insurance_company, insurance_policy_number,
		insurance_expiry_date, last_maintenance_date, next_maintenance_date,
		maintenance_notes, created_by
	) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19)
	RETURNING id, created_at, updated_at`

	var vehicle models.Vehicle
	err = db.QueryRow(query,
		req.RegistrationNumber, req.VehicleType, req.Brand, req.Model, req.Year,
		req.ChassisNumber, req.EngineNumber, req.Color, req.CapacityWeight, req.CapacityVolume,
		req.OwnershipStatus, operationalStatus, req.InsuranceCompany, req.InsurancePolicyNumber,
		insuranceExpiry, lastMaintenance, nextMaintenance, req.MaintenanceNotes, userID,
	).Scan(&vehicle.ID, &vehicle.CreatedAt, &vehicle.UpdatedAt)

	if err != nil {
		return nil, fmt.Errorf("failed to create vehicle: %v", err)
	}

	// Fill vehicle struct with request data
	vehicle.RegistrationNumber = req.RegistrationNumber
	vehicle.VehicleType = req.VehicleType
	vehicle.Brand = req.Brand
	vehicle.Model = req.Model
	vehicle.Year = req.Year
	vehicle.ChassisNumber = req.ChassisNumber
	vehicle.EngineNumber = req.EngineNumber
	vehicle.Color = req.Color
	vehicle.CapacityWeight = req.CapacityWeight
	vehicle.CapacityVolume = req.CapacityVolume
	vehicle.OwnershipStatus = req.OwnershipStatus
	vehicle.OperationalStatus = operationalStatus
	vehicle.InsuranceCompany = req.InsuranceCompany
	vehicle.InsurancePolicyNumber = req.InsurancePolicyNumber
	vehicle.InsuranceExpiryDate = insuranceExpiry
	vehicle.LastMaintenanceDate = lastMaintenance
	vehicle.NextMaintenanceDate = nextMaintenance
	vehicle.MaintenanceNotes = req.MaintenanceNotes
	vehicle.CreatedBy = userID

	return &vehicle, nil
}

func GetVehicles(db *sql.DB) ([]models.Vehicle, error) {
	query := `SELECT id, registration_number, vehicle_type, brand, model, year,
		chassis_number, engine_number, color, capacity_weight, capacity_volume,
		ownership_status, operational_status, insurance_company, insurance_policy_number,
		insurance_expiry_date, last_maintenance_date, next_maintenance_date,
		maintenance_notes, created_by, created_at, updated_at
		FROM vehicles ORDER BY created_at DESC`

	rows, err := db.Query(query)
	if err != nil {
		log.Printf("Database error: failed to get vehicles: %v", middleware.SanitizeForLog(err.Error()))
		return nil, fmt.Errorf("failed to get vehicles: %v", err)
	}
	defer rows.Close()

	var vehicles []models.Vehicle
	for rows.Next() {
		var v models.Vehicle
		err := rows.Scan(
			&v.ID, &v.RegistrationNumber, &v.VehicleType, &v.Brand, &v.Model, &v.Year,
			&v.ChassisNumber, &v.EngineNumber, &v.Color, &v.CapacityWeight, &v.CapacityVolume,
			&v.OwnershipStatus, &v.OperationalStatus, &v.InsuranceCompany, &v.InsurancePolicyNumber,
			&v.InsuranceExpiryDate, &v.LastMaintenanceDate, &v.NextMaintenanceDate,
			&v.MaintenanceNotes, &v.CreatedBy, &v.CreatedAt, &v.UpdatedAt,
		)
		if err != nil {
			log.Printf("Database error: failed to scan vehicle row: %v", middleware.SanitizeForLog(err.Error()))
			return nil, fmt.Errorf("failed to scan vehicle: %v", err)
		}
		vehicles = append(vehicles, v)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("error during rows iteration: %v", err)
	}

	return vehicles, nil
}

func GetVehicleByID(db *sql.DB, id int) (*models.Vehicle, error) {
	query := `SELECT id, registration_number, vehicle_type, brand, model, year,
		chassis_number, engine_number, color, capacity_weight, capacity_volume,
		ownership_status, operational_status, insurance_company, insurance_policy_number,
		insurance_expiry_date, last_maintenance_date, next_maintenance_date,
		maintenance_notes, created_by, created_at, updated_at
		FROM vehicles WHERE id = $1`

	var v models.Vehicle
	err := db.QueryRow(query, id).Scan(
		&v.ID, &v.RegistrationNumber, &v.VehicleType, &v.Brand, &v.Model, &v.Year,
		&v.ChassisNumber, &v.EngineNumber, &v.Color, &v.CapacityWeight, &v.CapacityVolume,
		&v.OwnershipStatus, &v.OperationalStatus, &v.InsuranceCompany, &v.InsurancePolicyNumber,
		&v.InsuranceExpiryDate, &v.LastMaintenanceDate, &v.NextMaintenanceDate,
		&v.MaintenanceNotes, &v.CreatedBy, &v.CreatedAt, &v.UpdatedAt,
	)

	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("vehicle not found")
		}
		return nil, fmt.Errorf("failed to get vehicle: %v", err)
	}

	return &v, nil
}

// parseOptionalDate parses optional date string
func parseOptionalDate(dateStr *string, fieldName string) (*time.Time, error) {
	if dateStr == nil || *dateStr == "" {
		return nil, nil
	}
	t, err := time.Parse("2006-01-02", *dateStr)
	if err != nil {
		return nil, fmt.Errorf("invalid %s date format: %v", fieldName, err)
	}
	return &t, nil
}