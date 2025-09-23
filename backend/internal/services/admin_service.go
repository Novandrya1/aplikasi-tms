package services

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"log"
	"strings"
	"time"
)

func GetPendingVehicles(db *sql.DB) ([]map[string]interface{}, error) {
	query := `SELECT v.id, v.registration_number, v.vehicle_type, v.brand, v.model, v.year,
			  v.verification_status, v.verification_substatus, v.created_at,
			  COALESCE(fo.company_name, '') as company_name, 
			  COALESCE(fo.owner_name, u.full_name, '') as full_name, 
			  COALESCE(fo.email, u.email, '') as email,
			  CASE WHEN fo.company_name IS NOT NULL AND fo.company_name != '' THEN 'company' ELSE 'individual' END as owner_type,
			  EXTRACT(DAY FROM (CURRENT_TIMESTAMP - v.created_at)) as days_waiting
			  FROM vehicles v
			  LEFT JOIN fleet_owners fo ON v.fleet_owner_id = fo.id
			  LEFT JOIN users u ON fo.user_id = u.id
			  WHERE (v.verification_status IN ('pending', 'submitted') OR v.verification_substatus IN ('awaiting_review', 'needs_correction', 'under_review'))
			  AND v.fleet_owner_id IS NOT NULL
			  ORDER BY v.created_at ASC`

	rows, err := db.Query(query)
	if err != nil {
		return nil, fmt.Errorf("failed to get pending vehicles: %s", strings.ReplaceAll(err.Error(), "\n", " "))
	}
	defer rows.Close()

	var vehicles []map[string]interface{}
	for rows.Next() {
		var v map[string]interface{} = make(map[string]interface{})
		var id, year, daysWaiting int
		var regNumber, vehicleType, brand, model, status, substatus, ownerType string
		var createdAt string
		var companyName, fullName, email string

		err := rows.Scan(&id, &regNumber, &vehicleType, &brand, &model, &year,
			&status, &substatus, &createdAt, &companyName, &fullName, &email, &ownerType, &daysWaiting)
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
		v["verification_substatus"] = substatus
		v["created_at"] = createdAt
		v["company_name"] = companyName
		v["owner_name"] = fullName
		v["owner_email"] = email
		v["owner_type"] = ownerType
		v["days_waiting"] = daysWaiting
		
		// Set priority based on days waiting and status
		priority := "normal"
		if daysWaiting > 3 {
			priority = "high"
		} else if daysWaiting > 7 {
			priority = "urgent"
		}
		v["priority"] = priority

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
	// Validate status - now supports more statuses
	validStatuses := []string{"approved", "rejected", "needs_correction", "under_review", "pending_inspection"}
	validStatus := false
	for _, vs := range validStatuses {
		if status == vs {
			validStatus = true
			break
		}
	}
	if !validStatus {
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

	// Update operational status and substatus based on verification
	operationalStatus := "inactive"
	substatus := "initial"
	
	switch status {
	case "approved":
		operationalStatus = "active"
		substatus = "approved"
	case "rejected":
		operationalStatus = "inactive"
		substatus = "rejected"
	case "needs_correction":
		operationalStatus = "pending_verification"
		substatus = "needs_correction"
	case "under_review":
		operationalStatus = "pending_verification"
		substatus = "under_review"
	case "pending_inspection":
		operationalStatus = "pending_verification"
		substatus = "pending_inspection"
	}

	// Update vehicle status with substatus
	query := `UPDATE vehicles 
			  SET verification_status = $1, verification_substatus = $2, operational_status = $3, 
			      verification_notes = $4, verified_by = $5, verified_at = CURRENT_TIMESTAMP, 
			      updated_at = CURRENT_TIMESTAMP
			  WHERE id = $6`

	_, err = tx.Exec(query, status, substatus, operationalStatus, adminNotes, adminID, vehicleID)
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
		notificationService := NewNotificationService(db)
		templateKey := "approved"
		extraVars := map[string]interface{}{}
		
		if status == "rejected" {
			templateKey = "rejected"
			extraVars["reason"] = adminNotes
		}
		
		err := notificationService.SendVehicleNotification(vehicleID, templateKey, extraVars)
		if err != nil {
			log.Printf("Failed to send verification notification: %v", err)
		}
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

	// Pending vehicles (including submitted)
	var pendingVehicles int
	err = db.QueryRow("SELECT COUNT(*) FROM vehicles WHERE verification_status IN ('pending', 'submitted') OR verification_substatus IN ('awaiting_review', 'needs_correction', 'under_review')").Scan(&pendingVehicles)
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
			  v.ownership_status, v.operational_status, v.verification_status, v.verification_substatus,
			  v.insurance_company, v.insurance_policy_number, v.insurance_expiry_date,
			  v.last_maintenance_date, v.next_maintenance_date, v.maintenance_notes,
			  v.created_at, v.updated_at,
			  COALESCE(fo.company_name, '') as company_name, 
			  COALESCE(fo.business_license, '') as business_license, 
			  COALESCE(fo.address, '') as address, 
			  COALESCE(fo.phone, '') as phone,
			  COALESCE(fo.email, '') as owner_email_fo,
			  COALESCE(fo.owner_name, '') as owner_name_fo,
			  COALESCE(fo.ktp_number, '') as ktp_number,
			  COALESCE(fo.npwp, '') as npwp,
			  COALESCE(u.full_name, '') as full_name, 
			  COALESCE(u.email, '') as email, 
			  COALESCE(u.username, '') as username
			  FROM vehicles v
			  LEFT JOIN fleet_owners fo ON v.fleet_owner_id = fo.id
			  LEFT JOIN users u ON fo.user_id = u.id
			  WHERE v.id = $1`

	var vehicle map[string]interface{} = make(map[string]interface{})
	
	row := db.QueryRow(query, vehicleID)
	
	var id, year int
	var regNumber, vehicleType, brand, model, chassisNumber, engineNumber, color string
	var capacityWeight, capacityVolume sql.NullFloat64
	var ownershipStatus, operationalStatus, verificationStatus, verificationSubstatus string
	var insuranceCompany, insurancePolicyNumber sql.NullString
	var insuranceExpiryDate, lastMaintenanceDate, nextMaintenanceDate sql.NullTime
	var maintenanceNotes sql.NullString
	var createdAt, updatedAt string
	var companyName, businessLicense, address, phone, ownerEmailFo, ownerNameFo, ktpNumber, npwp string
	var fullName, email, username string

	err := row.Scan(
		&id, &regNumber, &vehicleType, &brand, &model, &year,
		&chassisNumber, &engineNumber, &color, &capacityWeight, &capacityVolume,
		&ownershipStatus, &operationalStatus, &verificationStatus, &verificationSubstatus,
		&insuranceCompany, &insurancePolicyNumber, &insuranceExpiryDate,
		&lastMaintenanceDate, &nextMaintenanceDate, &maintenanceNotes,
		&createdAt, &updatedAt,
		&companyName, &businessLicense, &address, &phone,
		&ownerEmailFo, &ownerNameFo, &ktpNumber, &npwp,
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
	vehicle["verification_substatus"] = verificationSubstatus
	
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
	
	// Fleet owner info - prioritize fleet_owners table data
	vehicle["company_name"] = companyName
	vehicle["business_license"] = businessLicense
	vehicle["owner_address"] = address
	vehicle["owner_phone"] = phone
	vehicle["ktp_number"] = ktpNumber
	vehicle["npwp"] = npwp
	
	// Use fleet owner data if available, otherwise use user data
	if ownerNameFo != "" {
		vehicle["owner_name"] = ownerNameFo
	} else {
		vehicle["owner_name"] = fullName
	}
	
	if ownerEmailFo != "" {
		vehicle["owner_email"] = ownerEmailFo
	} else {
		vehicle["owner_email"] = email
	}
	
	vehicle["owner_username"] = username
	
	// Determine owner type
	if companyName != "" {
		vehicle["owner_type"] = "company"
	} else {
		vehicle["owner_type"] = "individual"
	}

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

// Enhanced admin verification functions

func GetVehiclesByStatus(db *sql.DB, status string) ([]map[string]interface{}, error) {
	query := `SELECT v.id, v.registration_number, v.vehicle_type, v.brand, v.model, v.year,
			  v.verification_status, v.verification_substatus, v.operational_status, 
			  v.created_at, v.verified_at, v.verification_notes,
			  COALESCE(fo.company_name, '') as company_name, 
			  COALESCE(u.full_name, '') as full_name, 
			  COALESCE(u.email, '') as email,
			  CASE WHEN fo.company_name IS NOT NULL THEN 'company' ELSE 'individual' END as owner_type,
			  EXTRACT(DAY FROM (CURRENT_TIMESTAMP - v.created_at)) as days_waiting
			  FROM vehicles v
			  LEFT JOIN fleet_owners fo ON v.fleet_owner_id = fo.id
			  LEFT JOIN users u ON fo.user_id = u.id
			  WHERE v.verification_status = $1 OR v.verification_substatus = $1
			  ORDER BY v.created_at DESC`

	rows, err := db.Query(query, status)
	if err != nil {
		return nil, fmt.Errorf("failed to get vehicles by status: %s", strings.ReplaceAll(err.Error(), "\n", " "))
	}
	defer rows.Close()

	var vehicles []map[string]interface{}
	for rows.Next() {
		var v map[string]interface{} = make(map[string]interface{})
		var id, year, daysWaiting int
		var regNumber, vehicleType, brand, model, verificationStatus, substatus, operationalStatus, ownerType string
		var createdAt string
		var verifiedAt sql.NullString
		var notes sql.NullString
		var companyName, fullName, email string

		err := rows.Scan(&id, &regNumber, &vehicleType, &brand, &model, &year,
			&verificationStatus, &substatus, &operationalStatus, &createdAt, &verifiedAt, &notes,
			&companyName, &fullName, &email, &ownerType, &daysWaiting)
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
		v["verification_substatus"] = substatus
		v["operational_status"] = operationalStatus
		v["created_at"] = createdAt
		v["company_name"] = companyName
		v["owner_name"] = fullName
		v["owner_email"] = email
		v["owner_type"] = ownerType
		v["days_waiting"] = daysWaiting
		
		if verifiedAt.Valid {
			v["verified_at"] = verifiedAt.String
		}
		if notes.Valid {
			v["verification_notes"] = notes.String
		}

		vehicles = append(vehicles, v)
	}

	return vehicles, nil
}

func GetAdminVerificationDashboard(db *sql.DB) (map[string]interface{}, error) {
	dashboard := make(map[string]interface{})

	// Get counts by status
	
	statusQuery := `SELECT 
		COUNT(CASE WHEN (verification_status IN ('pending', 'submitted') OR verification_substatus IN ('awaiting_review', 'needs_correction', 'under_review')) AND fleet_owner_id IS NOT NULL THEN 1 END) as pending_count,
		COUNT(CASE WHEN verification_substatus = 'needs_correction' THEN 1 END) as needs_correction_count,
		COUNT(CASE WHEN verification_substatus = 'under_review' THEN 1 END) as under_review_count,
		COUNT(CASE WHEN verification_status = 'approved' AND DATE(verified_at) = CURRENT_DATE THEN 1 END) as approved_today,
		COUNT(CASE WHEN verification_status = 'rejected' AND DATE(verified_at) = CURRENT_DATE THEN 1 END) as rejected_today
		FROM vehicles`

	var pendingCount, needsCorrectionCount, underReviewCount, approvedToday, rejectedToday int
	err := db.QueryRow(statusQuery).Scan(&pendingCount, &needsCorrectionCount, &underReviewCount, &approvedToday, &rejectedToday)
	if err != nil {
		return nil, fmt.Errorf("failed to get status counts: %v", err)
	}

	dashboard["pending_count"] = pendingCount
	dashboard["needs_correction_count"] = needsCorrectionCount
	dashboard["under_review_count"] = underReviewCount
	dashboard["approved_today"] = approvedToday
	dashboard["rejected_today"] = rejectedToday

	// Get recent submissions (last 10)
	recentQuery := `SELECT v.id, v.registration_number, 
		COALESCE(fo.company_name, u.full_name) as owner_name,
		CASE WHEN fo.company_name IS NOT NULL THEN 'company' ELSE 'individual' END as owner_type,
		v.verification_status, v.verification_substatus, v.created_at,
		EXTRACT(DAY FROM (CURRENT_TIMESTAMP - v.created_at)) as days_waiting
		FROM vehicles v
		LEFT JOIN fleet_owners fo ON v.fleet_owner_id = fo.id
		LEFT JOIN users u ON fo.user_id = u.id
		WHERE v.verification_status IN ('pending', 'submitted', 'needs_correction', 'under_review')
		ORDER BY v.created_at DESC LIMIT 10`

	rows, err := db.Query(recentQuery)
	if err != nil {
		return nil, fmt.Errorf("failed to get recent submissions: %v", err)
	}
	defer rows.Close()

	var recentSubmissions []map[string]interface{}
	for rows.Next() {
		var submission map[string]interface{} = make(map[string]interface{})
		var id, daysWaiting int
		var regNumber, ownerName, ownerType, status, substatus, createdAt string

		err := rows.Scan(&id, &regNumber, &ownerName, &ownerType, &status, &substatus, &createdAt, &daysWaiting)
		if err != nil {
			continue
		}

		submission["id"] = id
		submission["registration_number"] = regNumber
		submission["owner_name"] = ownerName
		submission["owner_type"] = ownerType
		submission["status"] = status
		submission["substatus"] = substatus
		submission["submitted_at"] = createdAt
		submission["days_waiting"] = daysWaiting

		// Set priority
		priority := "normal"
		if daysWaiting > 7 {
			priority = "urgent"
		} else if daysWaiting > 3 {
			priority = "high"
		}
		submission["priority"] = priority

		recentSubmissions = append(recentSubmissions, submission)
	}
	dashboard["recent_submissions"] = recentSubmissions

	// Get urgent items (overdue verifications)
	urgentQuery := `SELECT v.id, v.registration_number,
		EXTRACT(DAY FROM (CURRENT_TIMESTAMP - v.created_at)) as days_overdue
		FROM vehicles v
		WHERE v.verification_status IN ('pending', 'submitted', 'under_review') 
		AND v.created_at < CURRENT_TIMESTAMP - INTERVAL '7 days'
		ORDER BY v.created_at ASC LIMIT 5`

	urgentRows, err := db.Query(urgentQuery)
	if err != nil {
		return nil, fmt.Errorf("failed to get urgent items: %v", err)
	}
	defer urgentRows.Close()

	var urgentItems []map[string]interface{}
	for urgentRows.Next() {
		var item map[string]interface{} = make(map[string]interface{})
		var vehicleID, daysOverdue int
		var regNumber string

		err := urgentRows.Scan(&vehicleID, &regNumber, &daysOverdue)
		if err != nil {
			continue
		}

		item["vehicle_id"] = vehicleID
		item["registration_number"] = regNumber
		item["urgency_type"] = "overdue_verification"
		item["message"] = fmt.Sprintf("Verifikasi tertunda %d hari", daysOverdue)
		item["days_overdue"] = daysOverdue

		urgentItems = append(urgentItems, item)
	}
	dashboard["urgent_items"] = urgentItems

	return dashboard, nil
}

func PerformCrossCheck(db *sql.DB, vehicleID int, checkType string) (map[string]interface{}, error) {
	result := make(map[string]interface{})
	
	// Get vehicle details for cross-checking
	var regNumber, chassisNumber, engineNumber string
	err := db.QueryRow("SELECT registration_number, chassis_number, engine_number FROM vehicles WHERE id = $1", 
		vehicleID).Scan(&regNumber, &chassisNumber, &engineNumber)
	if err != nil {
		return nil, fmt.Errorf("vehicle not found: %v", err)
	}

	switch checkType {
	case "samsat":
		result = performSamsatCheck(regNumber)
	case "kir":
		result = performKIRCheck(regNumber)
	case "insurance":
		result = performInsuranceCheck(regNumber)
	case "duplicate":
		result = performDuplicateCheck(db, regNumber, chassisNumber, engineNumber, vehicleID)
	default:
		return nil, fmt.Errorf("unknown check type: %s", checkType)
	}

	// Store cross-check result in database
	insertQuery := `INSERT INTO fraud_checks (vehicle_id, check_type, result, confidence_score, details)
		VALUES ($1, $2, $3, $4, $5)`
	
	confidence := result["confidence"].(float64)
	status := result["status"].(string)
	details, _ := json.Marshal(result["details"])
	
	_, err = db.Exec(insertQuery, vehicleID, checkType, status, confidence, string(details))
	if err != nil {
		log.Printf("Failed to store cross-check result: %v", err)
	}

	return result, nil
}

func performSamsatCheck(regNumber string) map[string]interface{} {
	// Simulate Samsat API check
	result := make(map[string]interface{})
	result["check_type"] = "samsat"
	result["status"] = "passed"
	result["confidence"] = 0.95
	result["message"] = fmt.Sprintf("Nomor polisi %s terdaftar dan pajak aktif", regNumber)
	result["details"] = map[string]interface{}{
		"registration_valid": true,
		"tax_status": "active",
		"last_tax_payment": "2024-01-15",
		"next_due_date": "2025-01-15",
	}
	return result
}

func performKIRCheck(regNumber string) map[string]interface{} {
	// Simulate KIR validation
	result := make(map[string]interface{})
	result["check_type"] = "kir"
	result["status"] = "passed"
	result["confidence"] = 0.90
	result["message"] = "Kendaraan memiliki KIR yang masih berlaku"
	result["details"] = map[string]interface{}{
		"kir_valid": true,
		"issue_date": "2024-06-01",
		"expiry_date": "2025-06-01",
		"inspection_station": "Dishub Jakarta Pusat",
	}
	return result
}

func performInsuranceCheck(regNumber string) map[string]interface{} {
	// Simulate insurance validation
	result := make(map[string]interface{})
	result["check_type"] = "insurance"
	result["status"] = "passed"
	result["confidence"] = 0.88
	result["message"] = "Asuransi aktif dan sesuai dengan data kendaraan"
	result["details"] = map[string]interface{}{
		"policy_active": true,
		"insurance_company": "Asuransi Jasa Indonesia",
		"policy_number": "AJI-2024-001234",
		"coverage_type": "comprehensive",
		"expiry_date": "2025-03-15",
	}
	return result
}

func performDuplicateCheck(db *sql.DB, regNumber, chassisNumber, engineNumber string, excludeVehicleID int) map[string]interface{} {
	result := make(map[string]interface{})
	
	// Check for duplicate registration number
	var count int
	err := db.QueryRow("SELECT COUNT(*) FROM vehicles WHERE registration_number = $1 AND id != $2", 
		regNumber, excludeVehicleID).Scan(&count)
	
	duplicateFound := false
	duplicateType := ""
	
	if err == nil && count > 0 {
		duplicateFound = true
		duplicateType = "registration_number"
	}
	
	// Check for duplicate chassis number
	if !duplicateFound {
		err = db.QueryRow("SELECT COUNT(*) FROM vehicles WHERE chassis_number = $1 AND id != $2", 
			chassisNumber, excludeVehicleID).Scan(&count)
		if err == nil && count > 0 {
			duplicateFound = true
			duplicateType = "chassis_number"
		}
	}
	
	// Check for duplicate engine number
	if !duplicateFound {
		err = db.QueryRow("SELECT COUNT(*) FROM vehicles WHERE engine_number = $1 AND id != $2", 
			engineNumber, excludeVehicleID).Scan(&count)
		if err == nil && count > 0 {
			duplicateFound = true
			duplicateType = "engine_number"
		}
	}

	result["check_type"] = "duplicate"
	if duplicateFound {
		result["status"] = "failed"
		result["confidence"] = 1.0
		result["message"] = fmt.Sprintf("Ditemukan duplikasi %s", duplicateType)
		result["details"] = map[string]interface{}{
			"duplicate_found": true,
			"duplicate_type": duplicateType,
			"duplicate_count": count,
		}
	} else {
		result["status"] = "passed"
		result["confidence"] = 1.0
		result["message"] = "Tidak ditemukan duplikasi nomor polisi, rangka, atau mesin"
		result["details"] = map[string]interface{}{
			"duplicate_found": false,
		}
	}
	
	return result
}

func UpdateVehicleWithCorrection(db *sql.DB, vehicleID int, correctionItems []string, adminNotes string, adminID int) error {
	tx, err := db.Begin()
	if err != nil {
		return fmt.Errorf("failed to start transaction: %v", err)
	}
	defer tx.Rollback()

	// Update vehicle status to needs_correction
	query := `UPDATE vehicles 
			  SET verification_status = 'pending', verification_substatus = 'needs_correction', 
			      verification_notes = $1, verified_by = $2, verified_at = CURRENT_TIMESTAMP, 
			      updated_at = CURRENT_TIMESTAMP
			  WHERE id = $3`

	_, err = tx.Exec(query, adminNotes, adminID, vehicleID)
	if err != nil {
		return fmt.Errorf("failed to update vehicle status: %v", err)
	}

	// Insert verification history with correction items
	historyQuery := `INSERT INTO verification_history 
		(vehicle_id, admin_id, previous_status, new_status, verification_substatus, admin_notes, correction_items)
		VALUES ($1, $2, 'pending', 'needs_correction', 'needs_correction', $3, $4)`
	
	correctionJSON, _ := json.Marshal(correctionItems)
	_, err = tx.Exec(historyQuery, vehicleID, adminID, adminNotes, string(correctionJSON))
	if err != nil {
		return fmt.Errorf("failed to insert verification history: %v", err)
	}

	return tx.Commit()
}

func ScheduleInspection(db *sql.DB, vehicleID int, inspectionDate time.Time, location string, adminID int) error {
	tx, err := db.Begin()
	if err != nil {
		return fmt.Errorf("failed to start transaction: %v", err)
	}
	defer tx.Rollback()

	// Update vehicle to pending_inspection
	query := `UPDATE vehicles 
			  SET verification_substatus = 'pending_inspection', 
			      inspection_scheduled_at = $1, requires_inspection = true,
			      updated_at = CURRENT_TIMESTAMP
			  WHERE id = $2`

	_, err = tx.Exec(query, inspectionDate, vehicleID)
	if err != nil {
		return fmt.Errorf("failed to update vehicle inspection schedule: %v", err)
	}

	// Create inspection record
	inspectionQuery := `INSERT INTO vehicle_inspections 
		(vehicle_id, inspector_id, inspection_type, scheduled_at, location, result)
		VALUES ($1, $2, 'physical', $3, $4, 'pending')`
	
	_, err = tx.Exec(inspectionQuery, vehicleID, adminID, inspectionDate, location)
	if err != nil {
		return fmt.Errorf("failed to create inspection record: %v", err)
	}

	return tx.Commit()
}

func GetVehicleAttachments(db *sql.DB, vehicleID int) ([]map[string]interface{}, error) {
	query := `SELECT id, vehicle_id, attachment_type, file_name, file_path, 
			  file_size, mime_type, uploaded_at
			  FROM vehicle_attachments 
			  WHERE vehicle_id = $1 
			  ORDER BY uploaded_at DESC`

	rows, err := db.Query(query, vehicleID)
	if err != nil {
		return nil, fmt.Errorf("failed to get vehicle attachments: %v", err)
	}
	defer rows.Close()

	var attachments []map[string]interface{}
	for rows.Next() {
		var attachment map[string]interface{} = make(map[string]interface{})
		var id, vehicleIDScanned int
		var fileSize sql.NullInt64
		var attachmentType, fileName, filePath, uploadedAt string
		var mimeType sql.NullString

		err := rows.Scan(&id, &vehicleIDScanned, &attachmentType, &fileName, &filePath, &fileSize, &mimeType, &uploadedAt)
		if err != nil {
			return nil, fmt.Errorf("failed to scan attachment: %v", err)
		}

		attachment["id"] = id
		attachment["vehicle_id"] = vehicleIDScanned
		attachment["attachment_type"] = attachmentType
		attachment["file_name"] = fileName
		attachment["file_path"] = filePath
		if fileSize.Valid {
			attachment["file_size"] = fileSize.Int64
		} else {
			attachment["file_size"] = 0
		}
		if mimeType.Valid {
			attachment["mime_type"] = mimeType.String
		} else {
			attachment["mime_type"] = ""
		}
		attachment["uploaded_at"] = uploadedAt

		attachments = append(attachments, attachment)
	}

	return attachments, nil
}