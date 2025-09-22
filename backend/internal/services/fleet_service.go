package services

import (
	"database/sql"
	"fmt"

	"github.com/youruser/aplikasi-tms/backend/internal/models"
)

func RegisterFleetOwner(db *sql.DB, req models.FleetOwnerRequest, userID int) (*models.FleetOwner, error) {
	// Start transaction for atomicity
	tx, err := db.Begin()
	if err != nil {
		return nil, fmt.Errorf("failed to start transaction: %v", err)
	}
	defer tx.Rollback() // Will be ignored if tx.Commit() succeeds

	// Update user type to fleet_owner
	_, err = tx.Exec("UPDATE users SET user_type = 'fleet_owner' WHERE id = $1", userID)
	if err != nil {
		return nil, fmt.Errorf("failed to update user type: %v", err)
	}

	// Insert fleet owner record
	query := `INSERT INTO fleet_owners (user_id, company_name, business_license, address, phone, email) 
			  VALUES ($1, $2, $3, $4, $5, $6) RETURNING id, created_at, updated_at`

	var fleetOwner models.FleetOwner
	err = tx.QueryRow(query, userID, req.CompanyName, req.BusinessLicense, req.Address, req.PhoneNumber, req.Email).
		Scan(&fleetOwner.ID, &fleetOwner.CreatedAt, &fleetOwner.UpdatedAt)

	if err != nil {
		return nil, fmt.Errorf("failed to register fleet owner: %v", err)
	}

	// Commit transaction
	if err = tx.Commit(); err != nil {
		return nil, fmt.Errorf("failed to commit transaction: %v", err)
	}

	fleetOwner.UserID = userID
	fleetOwner.CompanyName = req.CompanyName
	fleetOwner.BusinessLicense = req.BusinessLicense
	fleetOwner.Address = req.Address
	fleetOwner.Phone = req.PhoneNumber
	fleetOwner.Verified = false

	// Create a default vehicle record for verification
	vehicleQuery := `INSERT INTO vehicles (
		registration_number, vehicle_type, brand, model, year,
		chassis_number, engine_number, color, capacity_weight, capacity_volume,
		ownership_status, operational_status, fleet_owner_id, verification_status
	) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14)`
	
	regNumber := "PENDING-" + fmt.Sprintf("%d", fleetOwner.ID)
	_, err = db.Exec(vehicleQuery,
		regNumber, "Truck", "Unknown", "Unknown", 2020,
		"PENDING", "PENDING", "Unknown", 1000.0, 10.0,
		"owned", "pending_verification", fleetOwner.ID, "pending",
	)
	
	if err != nil {
		fmt.Printf("Failed to create vehicle: %v\n", err)
	}
	
	// Send notifications asynchronously
	go func() {
		notifyAdminsFleetRegistration(db, req.CompanyName)
		notifyAdminsVehicleRegistration(db, regNumber)
	}()

	return &fleetOwner, nil
}

func GetFleetOwnerByUserID(db *sql.DB, userID int) (*models.FleetOwner, error) {
	query := `SELECT fo.id, fo.user_id, fo.company_name, fo.business_license, fo.address, 
			  fo.phone, fo.verified, fo.created_at, fo.updated_at,
			  u.username, u.email, u.full_name
			  FROM fleet_owners fo
			  LEFT JOIN users u ON fo.user_id = u.id
			  WHERE fo.user_id = $1`

	var fo models.FleetOwner
	var user models.User
	err := db.QueryRow(query, userID).Scan(
		&fo.ID, &fo.UserID, &fo.CompanyName, &fo.BusinessLicense, &fo.Address,
		&fo.Phone, &fo.Verified, &fo.CreatedAt, &fo.UpdatedAt,
		&user.Username, &user.Email, &user.FullName,
	)

	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("fleet owner not found")
		}
		return nil, fmt.Errorf("failed to get fleet owner: %v", err)
	}

	fo.User = &user
	return &fo, nil
}

func RegisterVehicleForFleet(db *sql.DB, req models.VehicleRegistrationRequest, fleetOwnerID int) (*models.Vehicle, error) {
	// Check if registration number already exists
	var exists bool
	checkQuery := "SELECT EXISTS(SELECT 1 FROM vehicles WHERE registration_number = $1)"
	err := db.QueryRow(checkQuery, req.RegistrationNumber).Scan(&exists)
	if err != nil {
		return nil, fmt.Errorf("failed to check vehicle existence: %v", err)
	}
	if exists {
		return nil, fmt.Errorf("vehicle with registration number already exists")
	}

	// Set defaults
	if req.OperationalStatus == "" {
		req.OperationalStatus = "pending_verification"
	}

	query := `INSERT INTO vehicles (
		registration_number, vehicle_type, brand, model, year,
		chassis_number, engine_number, color, capacity_weight, capacity_volume,
		ownership_status, operational_status, insurance_company, insurance_policy_number,
		insurance_expiry_date, last_maintenance_date, next_maintenance_date,
		maintenance_notes, fleet_owner_id, verification_status
	) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20)
	RETURNING id, created_at, updated_at`

	var vehicle models.Vehicle
	err = db.QueryRow(query,
		req.RegistrationNumber, req.VehicleType, req.Brand, req.Model, req.Year,
		req.ChassisNumber, req.EngineNumber, req.Color, req.CapacityWeight, req.CapacityVolume,
		req.OwnershipStatus, req.OperationalStatus, req.InsuranceCompany, req.InsurancePolicyNumber,
		req.InsuranceExpiryDate, req.LastMaintenanceDate, req.NextMaintenanceDate,
		req.MaintenanceNotes, fleetOwnerID, "pending",
	).Scan(&vehicle.ID, &vehicle.CreatedAt, &vehicle.UpdatedAt)

	if err != nil {
		return nil, fmt.Errorf("failed to register vehicle: %v", err)
	}

	// Fill vehicle struct
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
	vehicle.OperationalStatus = req.OperationalStatus
	vehicle.VerificationStatus = "pending"

	// Send notification to all admins about new vehicle registration
	go func() {
		notifyAdminsVehicleRegistration(db, req.RegistrationNumber)
	}()

	return &vehicle, nil
}

func GetFleetVehicles(db *sql.DB, fleetOwnerID int) ([]models.Vehicle, error) {
	query := `SELECT id, registration_number, vehicle_type, brand, model, year,
			  chassis_number, engine_number, color, capacity_weight, capacity_volume,
			  ownership_status, operational_status, verification_status,
			  created_at, updated_at
			  FROM vehicles 
			  WHERE fleet_owner_id = $1 
			  ORDER BY created_at DESC`

	rows, err := db.Query(query, fleetOwnerID)
	if err != nil {
		return nil, fmt.Errorf("failed to get fleet vehicles: %v", err)
	}
	defer rows.Close()

	var vehicles []models.Vehicle
	for rows.Next() {
		var v models.Vehicle
		err := rows.Scan(
			&v.ID, &v.RegistrationNumber, &v.VehicleType, &v.Brand, &v.Model, &v.Year,
			&v.ChassisNumber, &v.EngineNumber, &v.Color, &v.CapacityWeight, &v.CapacityVolume,
			&v.OwnershipStatus, &v.OperationalStatus, &v.VerificationStatus,
			&v.CreatedAt, &v.UpdatedAt,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan vehicle: %v", err)
		}
		vehicles = append(vehicles, v)
	}

	// Check for iteration errors
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("error during row iteration: %v", err)
	}

	return vehicles, nil
}

func notifyAdminsFleetRegistration(db *sql.DB, companyName string) {
	// Get all admin users
	query := `SELECT id FROM users WHERE role = 'admin'`
	rows, err := db.Query(query)
	if err != nil {
		return
	}
	defer rows.Close()

	title := "Registrasi Armada Baru"
	message := fmt.Sprintf("Perusahaan '%s' telah mendaftar sebagai pemilik armada dan menunggu verifikasi admin.", companyName)

	for rows.Next() {
		var adminID int
		if err := rows.Scan(&adminID); err != nil {
			continue
		}
		
		// Create notification for each admin
		notifQuery := `INSERT INTO notifications (user_id, title, message, type) VALUES ($1, $2, $3, $4)`
		db.Exec(notifQuery, adminID, title, message, "info")
	}
}

func notifyAdminsVehicleRegistration(db *sql.DB, registrationNumber string) {
	// Get all admin users
	query := `SELECT id FROM users WHERE role = 'admin'`
	rows, err := db.Query(query)
	if err != nil {
		return
	}
	defer rows.Close()

	title := "Kendaraan Baru Perlu Verifikasi"
	message := fmt.Sprintf("Kendaraan dengan nomor polisi '%s' telah didaftarkan dan menunggu verifikasi admin.", registrationNumber)

	for rows.Next() {
		var adminID int
		if err := rows.Scan(&adminID); err != nil {
			continue
		}
		
		// Create notification for each admin
		notifQuery := `INSERT INTO notifications (user_id, title, message, type) VALUES ($1, $2, $3, $4)`
		db.Exec(notifQuery, adminID, title, message, "warning")
	}
}