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

	// Start transaction for complete registration
	tx, err := db.Begin()
	if err != nil {
		return nil, fmt.Errorf("failed to start transaction: %v", err)
	}
	defer tx.Rollback()

	query := `INSERT INTO vehicles (
		registration_number, vehicle_type, brand, model, year,
		chassis_number, engine_number, color, capacity_weight, capacity_volume,
		ownership_status, operational_status, insurance_company, insurance_policy_number,
		insurance_expiry_date, last_maintenance_date, next_maintenance_date,
		maintenance_notes, fleet_owner_id, verification_status, verification_substatus
	) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21)
	RETURNING id, created_at, updated_at`

	var vehicle models.Vehicle
	err = tx.QueryRow(query,
		req.RegistrationNumber, req.VehicleType, req.Brand, req.Model, req.Year,
		req.ChassisNumber, req.EngineNumber, req.Color, req.CapacityWeight, req.CapacityVolume,
		req.OwnershipStatus, req.OperationalStatus, req.InsuranceCompany, req.InsurancePolicyNumber,
		req.InsuranceExpiryDate, req.LastMaintenanceDate, req.NextMaintenanceDate,
		req.MaintenanceNotes, fleetOwnerID, "submitted", "awaiting_review",
	).Scan(&vehicle.ID, &vehicle.CreatedAt, &vehicle.UpdatedAt)

	if err != nil {
		return nil, fmt.Errorf("failed to register vehicle: %v", err)
	}

	// Save all documents if provided in request
	if req.Documents != nil {
		documents := req.Documents.(map[string]interface{})
		
		// Save owner documents
		if ktpFile, ok := documents["ktp_file"].(string); ok && ktpFile != "" {
			_, err = tx.Exec(`INSERT INTO vehicle_attachments (vehicle_id, attachment_type, file_path, file_name) 
							 VALUES ($1, $2, $3, $4)`, 
							 vehicle.ID, "ktp", ktpFile, "KTP_Pemilik.jpg")
			if err != nil {
				return nil, fmt.Errorf("failed to save KTP document: %v", err)
			}
		}
		
		if selfieFile, ok := documents["selfie_file"].(string); ok && selfieFile != "" {
			_, err = tx.Exec(`INSERT INTO vehicle_attachments (vehicle_id, attachment_type, file_path, file_name) 
							 VALUES ($1, $2, $3, $4)`, 
							 vehicle.ID, "selfie_ktp", selfieFile, "Selfie_KTP.jpg")
			if err != nil {
				return nil, fmt.Errorf("failed to save selfie document: %v", err)
			}
		}
		
		// Save vehicle documents
		if stnkFile, ok := documents["stnk_file"].(string); ok && stnkFile != "" {
			_, err = tx.Exec(`INSERT INTO vehicle_attachments (vehicle_id, attachment_type, file_path, file_name) 
							 VALUES ($1, $2, $3, $4)`, 
							 vehicle.ID, "stnk", stnkFile, "STNK.jpg")
			if err != nil {
				return nil, fmt.Errorf("failed to save STNK document: %v", err)
			}
		}
		
		if bpkbFile, ok := documents["bpkb_file"].(string); ok && bpkbFile != "" {
			_, err = tx.Exec(`INSERT INTO vehicle_attachments (vehicle_id, attachment_type, file_path, file_name) 
							 VALUES ($1, $2, $3, $4)`, 
							 vehicle.ID, "bpkb", bpkbFile, "BPKB.jpg")
			if err != nil {
				return nil, fmt.Errorf("failed to save BPKB document: %v", err)
			}
		}
		
		if taxFile, ok := documents["tax_file"].(string); ok && taxFile != "" {
			_, err = tx.Exec(`INSERT INTO vehicle_attachments (vehicle_id, attachment_type, file_path, file_name) 
							 VALUES ($1, $2, $3, $4)`, 
							 vehicle.ID, "tax_receipt", taxFile, "Bukti_Pajak.jpg")
			if err != nil {
				return nil, fmt.Errorf("failed to save tax document: %v", err)
			}
		}
		
		if insuranceFile, ok := documents["insurance_file"].(string); ok && insuranceFile != "" {
			_, err = tx.Exec(`INSERT INTO vehicle_attachments (vehicle_id, attachment_type, file_path, file_name) 
							 VALUES ($1, $2, $3, $4)`, 
							 vehicle.ID, "insurance", insuranceFile, "Asuransi.jpg")
			if err != nil {
				return nil, fmt.Errorf("failed to save insurance document: %v", err)
			}
		}
		
		// Save company documents if applicable
		if businessLicenseFile, ok := documents["business_license_file"].(string); ok && businessLicenseFile != "" {
			_, err = tx.Exec(`INSERT INTO vehicle_attachments (vehicle_id, attachment_type, file_path, file_name) 
							 VALUES ($1, $2, $3, $4)`, 
							 vehicle.ID, "business_license", businessLicenseFile, "SIUP_NIB.jpg")
			if err != nil {
				return nil, fmt.Errorf("failed to save business license: %v", err)
			}
		}
		
		if npwpFile, ok := documents["npwp_file"].(string); ok && npwpFile != "" {
			_, err = tx.Exec(`INSERT INTO vehicle_attachments (vehicle_id, attachment_type, file_path, file_name) 
							 VALUES ($1, $2, $3, $4)`, 
							 vehicle.ID, "npwp", npwpFile, "NPWP.jpg")
			if err != nil {
				return nil, fmt.Errorf("failed to save NPWP document: %v", err)
			}
		}
		
		// Save vehicle photos
		if vehiclePhotos, ok := documents["vehicle_photos"].([]interface{}); ok {
			for i, photo := range vehiclePhotos {
				if photoPath, ok := photo.(string); ok && photoPath != "" {
					photoType := fmt.Sprintf("vehicle_photo_%d", i+1)
					fileName := fmt.Sprintf("Foto_Kendaraan_%d.jpg", i+1)
					_, err = tx.Exec(`INSERT INTO vehicle_attachments (vehicle_id, attachment_type, file_path, file_name) 
									 VALUES ($1, $2, $3, $4)`, 
									 vehicle.ID, photoType, photoPath, fileName)
					if err != nil {
						return nil, fmt.Errorf("failed to save vehicle photo %d: %v", i+1, err)
					}
				}
			}
		}
	}

	// Save owner data for verification
	if req.OwnerData != nil {
		ownerData := req.OwnerData.(map[string]interface{})
		
		// Update fleet owner with complete data
		updateQuery := `UPDATE fleet_owners SET 
						owner_name = $1, ktp_number = $2, address = $3, phone = $4, email = $5,
						company_name = COALESCE($6, company_name), npwp = $7, business_license = COALESCE($8, business_license)
						WHERE id = $9`
						
		_, err = tx.Exec(updateQuery,
			ownerData["name"], ownerData["ktp_number"], ownerData["address"], 
			ownerData["phone"], ownerData["email"], ownerData["company_name"],
			ownerData["npwp"], ownerData["business_license"], fleetOwnerID)
			
		if err != nil {
			return nil, fmt.Errorf("failed to update owner data: %v", err)
		}
	}

	// Commit transaction
	if err = tx.Commit(); err != nil {
		return nil, fmt.Errorf("failed to commit transaction: %v", err)
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
	vehicle.VerificationStatus = "submitted"

	// Send notification to all admins about complete vehicle registration
	go func() {
		notifyAdminsCompleteVehicleRegistration(db, req.RegistrationNumber, vehicle.ID)
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

func notifyAdminsCompleteVehicleRegistration(db *sql.DB, registrationNumber string, vehicleID int) {
	// Get all admin users
	query := `SELECT id FROM users WHERE role = 'admin'`
	rows, err := db.Query(query)
	if err != nil {
		return
	}
	defer rows.Close()

	// Count documents for this vehicle
	countQuery := `SELECT COUNT(*) FROM vehicle_attachments WHERE vehicle_id = $1`
	var docCount int
	db.QueryRow(countQuery, vehicleID).Scan(&docCount)

	title := "Registrasi Lengkap Siap Verifikasi"
	message := fmt.Sprintf("Kendaraan '%s' telah mengirim registrasi lengkap dengan %d dokumen. Semua data dan dokumen siap untuk diverifikasi admin.", registrationNumber, docCount)

	for rows.Next() {
		var adminID int
		if err := rows.Scan(&adminID); err != nil {
			continue
		}
		
		// Create high priority notification for complete registration
		notifQuery := `INSERT INTO notifications (user_id, title, message, type, priority) VALUES ($1, $2, $3, $4, $5)`
		db.Exec(notifQuery, adminID, title, message, "success", "high")
	}
}