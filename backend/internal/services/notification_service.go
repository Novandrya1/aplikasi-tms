package services

import (
	"database/sql"
	"fmt"
)

func NotifyVehicleOwner(db *sql.DB, vehicleID int, status string, adminNotes string) {
	// Get vehicle owner user ID
	query := `SELECT fo.user_id, v.registration_number, fo.company_name 
			  FROM vehicles v 
			  JOIN fleet_owners fo ON v.fleet_owner_id = fo.id 
			  WHERE v.id = $1`
	
	var userID int
	var regNumber, companyName string
	err := db.QueryRow(query, vehicleID).Scan(&userID, &regNumber, &companyName)
	if err != nil {
		return
	}
	
	var title, message, notifType string
	
	if status == "approved" {
		title = "Kendaraan Disetujui"
		message = fmt.Sprintf("Selamat! Kendaraan %s (%s) telah disetujui dan aktif dalam sistem. Anda dapat mulai menerima order transportasi.", regNumber, companyName)
		notifType = "success"
		
		// Add vehicle to user's fleet management
		AddVehicleToFleetManagement(db, vehicleID, userID)
	} else {
		title = "Kendaraan Ditolak"
		message = fmt.Sprintf("Kendaraan %s (%s) ditolak verifikasi. Catatan: %s. Silakan perbaiki dokumen dan daftar ulang.", regNumber, companyName, adminNotes)
		notifType = "error"
	}
	
	// Insert notification
	notifQuery := `INSERT INTO notifications (user_id, title, message, type) VALUES ($1, $2, $3, $4)`
	db.Exec(notifQuery, userID, title, message, notifType)
}

func AddVehicleToFleetManagement(db *sql.DB, vehicleID int, userID int) {
	// Update vehicle operational status to active
	updateQuery := `UPDATE vehicles SET operational_status = 'active' WHERE id = $1`
	db.Exec(updateQuery, vehicleID)
	
	// Create fleet management entry (if table exists)
	fleetQuery := `INSERT INTO user_vehicles (user_id, vehicle_id, role, created_at) 
				   VALUES ($1, $2, 'owner', CURRENT_TIMESTAMP) 
				   ON CONFLICT (user_id, vehicle_id) DO NOTHING`
	db.Exec(fleetQuery, userID, vehicleID)
}