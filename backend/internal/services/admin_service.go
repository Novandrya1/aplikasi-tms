package services

import (
	"database/sql"
	"fmt"
	"strings"
)

func GetPendingVehicles(db *sql.DB) ([]map[string]interface{}, error) {
	query := `SELECT v.id, v.registration_number, v.vehicle_type, v.brand, v.model, v.year,
			  v.verification_status, v.created_at,
			  fo.company_name, u.full_name, u.email
			  FROM vehicles v
			  LEFT JOIN fleet_owners fo ON v.fleet_owner_id = fo.id
			  LEFT JOIN users u ON fo.user_id = u.id
			  WHERE v.verification_status = 'pending'
			  ORDER BY v.created_at ASC`

	rows, err := db.Query(query)
	if err != nil {
		return nil, fmt.Errorf("failed to get pending vehicles: %s", strings.ReplaceAll(err.Error(), "\n", " "))
	}
	defer rows.Close()

	var vehicles []map[string]interface{}
	for rows.Next() {
		var v map[string]interface{} = make(map[string]interface{})
		var id, year int
		var regNumber, vehicleType, brand, model, status string
		var createdAt string
		var companyName, fullName, email sql.NullString

		err := rows.Scan(&id, &regNumber, &vehicleType, &brand, &model, &year,
			&status, &createdAt, &companyName, &fullName, &email)
		if err != nil {
			return nil, fmt.Errorf("failed to scan vehicle: %s", strings.ReplaceAll(err.Error(), "\n", " "))
		}

		v["id"] = id
		v["registration_number"] = regNumber
		v["vehicle_type"] = vehicleType
		v["brand"] = brand
		v["model"] = model
		v["year"] = year
		v["verification_status"] = status
		v["created_at"] = createdAt
		
		if companyName.Valid {
			v["company_name"] = companyName.String
		} else {
			v["company_name"] = ""
		}
		if fullName.Valid {
			v["owner_name"] = fullName.String
		} else {
			v["owner_name"] = ""
		}
		if email.Valid {
			v["owner_email"] = email.String
		} else {
			v["owner_email"] = ""
		}

		vehicles = append(vehicles, v)
	}

	return vehicles, nil
}

func GetAllVehiclesForAdmin(db *sql.DB) ([]map[string]interface{}, error) {
	query := `SELECT v.id, v.registration_number, v.vehicle_type, v.brand, v.model, v.year,
			  v.verification_status, v.operational_status, v.created_at, v.verified_at, v.admin_notes,
			  fo.company_name, u.full_name, u.email
			  FROM vehicles v
			  LEFT JOIN fleet_owners fo ON v.fleet_owner_id = fo.id
			  LEFT JOIN users u ON fo.user_id = u.id
			  ORDER BY v.created_at DESC`

	rows, err := db.Query(query)
	if err != nil {
		return nil, fmt.Errorf("failed to get vehicles: %s", strings.ReplaceAll(err.Error(), "\n", " "))
	}
	defer rows.Close()

	var vehicles []map[string]interface{}
	for rows.Next() {
		var v map[string]interface{} = make(map[string]interface{})
		var id, year int
		var regNumber, vehicleType, brand, model, verificationStatus, operationalStatus string
		var createdAt string
		var verifiedAt sql.NullString
		var adminNotes sql.NullString
		var companyName, fullName, email sql.NullString

		err := rows.Scan(&id, &regNumber, &vehicleType, &brand, &model, &year,
			&verificationStatus, &operationalStatus, &createdAt, &verifiedAt, &adminNotes,
			&companyName, &fullName, &email)
		if err != nil {
			return nil, fmt.Errorf("failed to scan vehicle: %s", strings.ReplaceAll(err.Error(), "\n", " "))
		}

		v["id"] = id
		v["registration_number"] = regNumber
		v["vehicle_type"] = vehicleType
		v["brand"] = brand
		v["model"] = model
		v["year"] = year
		v["verification_status"] = verificationStatus
		v["operational_status"] = operationalStatus
		v["created_at"] = createdAt
		if verifiedAt.Valid {
			v["verified_at"] = verifiedAt.String
		}
		if adminNotes.Valid {
			v["admin_notes"] = adminNotes.String
		}
		
		if companyName.Valid {
			v["company_name"] = companyName.String
		} else {
			v["company_name"] = ""
		}
		if fullName.Valid {
			v["owner_name"] = fullName.String
		} else {
			v["owner_name"] = ""
		}
		if email.Valid {
			v["owner_email"] = email.String
		} else {
			v["owner_email"] = ""
		}

		vehicles = append(vehicles, v)
	}

	return vehicles, nil
}

func UpdateVehicleVerificationStatus(db *sql.DB, vehicleID int, status string, adminNotes string, adminID int) error {
	// Validate status
	if status != "approved" && status != "rejected" {
		return fmt.Errorf("invalid status: %s", status)
	}

	// Start transaction
	tx, err := db.Begin()
	if err != nil {
		return fmt.Errorf("failed to start transaction: %v", err)
	}
	defer tx.Rollback()

	// Get current status for history
	var currentStatus string
	err = tx.QueryRow("SELECT verification_status FROM vehicles WHERE id = $1", vehicleID).Scan(&currentStatus)
	if err != nil {
		return fmt.Errorf("failed to get current status: %v", err)
	}

	// Update operational status based on verification
	operationalStatus := "inactive"
	if status == "approved" {
		operationalStatus = "active"
	}

	// Update vehicle status
	query := `UPDATE vehicles 
			  SET verification_status = $1, operational_status = $2, admin_notes = $3, 
			      verified_by = $4, verified_at = CURRENT_TIMESTAMP, updated_at = CURRENT_TIMESTAMP
			  WHERE id = $5`

	_, err = tx.Exec(query, status, operationalStatus, adminNotes, adminID, vehicleID)
	if err != nil {
		return fmt.Errorf("failed to update vehicle status: %v", err)
	}

	// Insert verification history
	historyQuery := `INSERT INTO verification_history (vehicle_id, admin_id, previous_status, new_status, admin_notes)
					 VALUES ($1, $2, $3, $4, $5)`
	_, err = tx.Exec(historyQuery, vehicleID, adminID, currentStatus, status, adminNotes)
	if err != nil {
		return fmt.Errorf("failed to insert verification history: %v", err)
	}

	// Commit transaction
	err = tx.Commit()
	if err != nil {
		return fmt.Errorf("failed to commit transaction: %v", err)
	}

	// Send notification to vehicle owner
	go func() {
		NotifyVehicleOwner(db, vehicleID, status, adminNotes)
	}()

	return nil
}

func GetAdminDashboardStats(db *sql.DB) (map[string]interface{}, error) {
	stats := make(map[string]interface{})

	// Total vehicles
	var totalVehicles int
	err := db.QueryRow("SELECT COUNT(*) FROM vehicles").Scan(&totalVehicles)
	if err != nil {
		return nil, fmt.Errorf("failed to get total vehicles: %v", err)
	}
	stats["total_vehicles"] = totalVehicles

	// Pending vehicles
	var pendingVehicles int
	err = db.QueryRow("SELECT COUNT(*) FROM vehicles WHERE verification_status = 'pending'").Scan(&pendingVehicles)
	if err != nil {
		return nil, fmt.Errorf("failed to get pending vehicles: %v", err)
	}
	stats["pending_vehicles"] = pendingVehicles

	// Approved vehicles
	var approvedVehicles int
	err = db.QueryRow("SELECT COUNT(*) FROM vehicles WHERE verification_status = 'approved'").Scan(&approvedVehicles)
	if err != nil {
		return nil, fmt.Errorf("failed to get approved vehicles: %v", err)
	}
	stats["approved_vehicles"] = approvedVehicles

	// Rejected vehicles
	var rejectedVehicles int
	err = db.QueryRow("SELECT COUNT(*) FROM vehicles WHERE verification_status = 'rejected'").Scan(&rejectedVehicles)
	if err != nil {
		return nil, fmt.Errorf("failed to get rejected vehicles: %v", err)
	}
	stats["rejected_vehicles"] = rejectedVehicles

	// Total fleet owners
	var totalFleetOwners int
	err = db.QueryRow("SELECT COUNT(*) FROM fleet_owners").Scan(&totalFleetOwners)
	if err != nil {
		return nil, fmt.Errorf("failed to get total fleet owners: %v", err)
	}
	stats["total_fleet_owners"] = totalFleetOwners

	// Active vehicles
	var activeVehicles int
	err = db.QueryRow("SELECT COUNT(*) FROM vehicles WHERE operational_status = 'active'").Scan(&activeVehicles)
	if err != nil {
		return nil, fmt.Errorf("failed to get active vehicles: %v", err)
	}
	stats["active_vehicles"] = activeVehicles

	return stats, nil
}

func GetVehicleDetailsForAdmin(db *sql.DB, vehicleID int) (map[string]interface{}, error) {
	query := `SELECT v.id, v.registration_number, v.vehicle_type, v.brand, v.model, v.year,
			  v.chassis_number, v.engine_number, v.color, v.capacity_weight, v.capacity_volume,
			  v.ownership_status, v.operational_status, v.verification_status,
			  v.insurance_company, v.insurance_policy_number, v.insurance_expiry_date,
			  v.last_maintenance_date, v.next_maintenance_date, v.maintenance_notes,
			  v.created_at, v.updated_at,
			  fo.company_name, fo.business_license, fo.address, fo.phone,
			  u.full_name, u.email, u.username
			  FROM vehicles v
			  LEFT JOIN fleet_owners fo ON v.fleet_owner_id = fo.id
			  LEFT JOIN users u ON fo.user_id = u.id
			  WHERE v.id = $1`

	var vehicle map[string]interface{} = make(map[string]interface{})
	
	row := db.QueryRow(query, vehicleID)
	
	var id, year int
	var regNumber, vehicleType, brand, model, chassisNumber, engineNumber, color string
	var capacityWeight, capacityVolume sql.NullFloat64
	var ownershipStatus, operationalStatus, verificationStatus string
	var insuranceCompany, insurancePolicyNumber sql.NullString
	var insuranceExpiryDate, lastMaintenanceDate, nextMaintenanceDate sql.NullTime
	var maintenanceNotes sql.NullString
	var createdAt, updatedAt string
	var companyName, businessLicense, address, phone, fullName, email, username string

	err := row.Scan(
		&id, &regNumber, &vehicleType, &brand, &model, &year,
		&chassisNumber, &engineNumber, &color, &capacityWeight, &capacityVolume,
		&ownershipStatus, &operationalStatus, &verificationStatus,
		&insuranceCompany, &insurancePolicyNumber, &insuranceExpiryDate,
		&lastMaintenanceDate, &nextMaintenanceDate, &maintenanceNotes,
		&createdAt, &updatedAt,
		&companyName, &businessLicense, &address, &phone,
		&fullName, &email, &username,
	)

	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("vehicle not found")
		}
		return nil, fmt.Errorf("failed to get vehicle details: %v", err)
	}

	// Map all fields
	vehicle["id"] = id
	vehicle["registration_number"] = regNumber
	vehicle["vehicle_type"] = vehicleType
	vehicle["brand"] = brand
	vehicle["model"] = model
	vehicle["year"] = year
	vehicle["chassis_number"] = chassisNumber
	vehicle["engine_number"] = engineNumber
	vehicle["color"] = color
	
	if capacityWeight.Valid {
		vehicle["capacity_weight"] = capacityWeight.Float64
	}
	if capacityVolume.Valid {
		vehicle["capacity_volume"] = capacityVolume.Float64
	}
	
	vehicle["ownership_status"] = ownershipStatus
	vehicle["operational_status"] = operationalStatus
	vehicle["verification_status"] = verificationStatus
	
	if insuranceCompany.Valid {
		vehicle["insurance_company"] = insuranceCompany.String
	}
	if insurancePolicyNumber.Valid {
		vehicle["insurance_policy_number"] = insurancePolicyNumber.String
	}
	if maintenanceNotes.Valid {
		vehicle["maintenance_notes"] = maintenanceNotes.String
	}
	
	vehicle["created_at"] = createdAt
	vehicle["updated_at"] = updatedAt
	
	// Fleet owner info
	vehicle["company_name"] = companyName
	vehicle["business_license"] = businessLicense
	vehicle["owner_address"] = address
	vehicle["owner_phone"] = phone
	vehicle["owner_name"] = fullName
	vehicle["owner_email"] = email
	vehicle["owner_username"] = username

	return vehicle, nil
}

func GetVerificationHistory(db *sql.DB, vehicleID int) ([]map[string]interface{}, error) {
	query := `SELECT vh.id, vh.previous_status, vh.new_status, vh.admin_notes, vh.verified_at,
			  u.full_name as admin_name, u.email as admin_email
			  FROM verification_history vh
			  LEFT JOIN users u ON vh.admin_id = u.id
			  WHERE vh.vehicle_id = $1
			  ORDER BY vh.verified_at DESC`

	rows, err := db.Query(query, vehicleID)
	if err != nil {
		return nil, fmt.Errorf("failed to get verification history: %v", err)
	}
	defer rows.Close()

	var history []map[string]interface{}
	for rows.Next() {
		var h map[string]interface{} = make(map[string]interface{})
		var id int
		var previousStatus, newStatus sql.NullString
		var adminNotes sql.NullString
		var verifiedAt string
		var adminName, adminEmail sql.NullString

		err := rows.Scan(&id, &previousStatus, &newStatus, &adminNotes, &verifiedAt, &adminName, &adminEmail)
		if err != nil {
			return nil, fmt.Errorf("failed to scan history: %v", err)
		}

		h["id"] = id
		if previousStatus.Valid {
			h["previous_status"] = previousStatus.String
		}
		h["new_status"] = newStatus.String
		if adminNotes.Valid {
			h["admin_notes"] = adminNotes.String
		}
		h["verified_at"] = verifiedAt
		if adminName.Valid {
			h["admin_name"] = adminName.String
		}
		if adminEmail.Valid {
			h["admin_email"] = adminEmail.String
		}

		history = append(history, h)
	}

	return history, nil
}

func GetApprovedVehicles(db *sql.DB) ([]map[string]interface{}, error) {
	query := `SELECT v.id, v.registration_number, v.vehicle_type, v.brand, v.model, v.year,
			  v.verification_status, v.operational_status, v.created_at, v.verified_at, v.admin_notes,
			  COALESCE(fo.company_name, '') as company_name, 
			  COALESCE(u.full_name, '') as full_name, 
			  COALESCE(u.email, '') as email
			  FROM vehicles v
			  LEFT JOIN fleet_owners fo ON v.fleet_owner_id = fo.id
			  LEFT JOIN users u ON fo.user_id = u.id
			  WHERE v.verification_status = 'approved'
			  ORDER BY v.created_at DESC`

	rows, err := db.Query(query)
	if err != nil {
		return nil, fmt.Errorf("failed to get approved vehicles: %s", strings.ReplaceAll(err.Error(), "\n", " "))
	}
	defer rows.Close()

	var vehicles []map[string]interface{}
	for rows.Next() {
		var v map[string]interface{} = make(map[string]interface{})
		var id, year int
		var regNumber, vehicleType, brand, model, verificationStatus, operationalStatus, companyName, fullName, email string
		var createdAt string
		var verifiedAt sql.NullString
		var adminNotes sql.NullString

		err := rows.Scan(&id, &regNumber, &vehicleType, &brand, &model, &year,
			&verificationStatus, &operationalStatus, &createdAt, &verifiedAt, &adminNotes,
			&companyName, &fullName, &email)
		if err != nil {
			return nil, fmt.Errorf("failed to scan vehicle: %s", strings.ReplaceAll(err.Error(), "\n", " "))
		}

		v["id"] = id
		v["registration_number"] = regNumber
		v["vehicle_type"] = vehicleType
		v["brand"] = brand
		v["model"] = model
		v["year"] = year
		v["verification_status"] = verificationStatus
		v["operational_status"] = operationalStatus
		v["created_at"] = createdAt
		if verifiedAt.Valid {
			v["verified_at"] = verifiedAt.String
		}
		if adminNotes.Valid {
			v["admin_notes"] = adminNotes.String
		}
		v["company_name"] = companyName
		v["owner_name"] = fullName
		v["owner_email"] = email

		vehicles = append(vehicles, v)
	}

	return vehicles, nil
}