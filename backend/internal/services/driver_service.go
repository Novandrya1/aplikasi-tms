package services

import (
	"database/sql"
	"fmt"
	"strings"
)

func GetDriverByUserID(db *sql.DB, userID int) (map[string]interface{}, error) {
	query := `SELECT d.id, d.user_id, d.license_number, d.status,
			  u.full_name, u.email
			  FROM drivers d
			  JOIN users u ON d.user_id = u.id
			  WHERE d.user_id = $1`

	var driver map[string]interface{} = make(map[string]interface{})
	var id, userIDVal int
	var licenseNumber, status, fullName, email string

	err := db.QueryRow(query, userID).Scan(&id, &userIDVal, &licenseNumber, &status, &fullName, &email)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("driver not found")
		}
		return nil, fmt.Errorf("failed to get driver: %v", err)
	}

	driver["id"] = id
	driver["user_id"] = userIDVal
	driver["license_number"] = licenseNumber
	driver["status"] = status
	driver["full_name"] = fullName
	driver["email"] = email

	return driver, nil
}

func GetDriverTrips(db *sql.DB, driverID int, status string) ([]map[string]interface{}, error) {
	query := `SELECT t.id, t.trip_number, t.origin_address, t.destination_address,
			  t.status, t.scheduled_start, t.cargo_description, t.driver_fee
			  FROM trips t
			  WHERE t.driver_id = $1`

	args := []interface{}{driverID}
	if status != "" {
		query += " AND t.status = $2"
		args = append(args, status)
	}
	query += " ORDER BY t.scheduled_start DESC"

	rows, err := db.Query(query, args...)
	if err != nil {
		return nil, fmt.Errorf("failed to get driver trips: %s", strings.ReplaceAll(err.Error(), "\n", " "))
	}
	defer rows.Close()

	var trips []map[string]interface{}
	for rows.Next() {
		var t map[string]interface{} = make(map[string]interface{})
		var id int
		var tripNumber, originAddress, destinationAddress, tripStatus string
		var cargoDescription sql.NullString
		var scheduledStart sql.NullTime
		var driverFee sql.NullFloat64

		err := rows.Scan(&id, &tripNumber, &originAddress, &destinationAddress,
			&tripStatus, &scheduledStart, &cargoDescription, &driverFee)
		if err != nil {
			return nil, fmt.Errorf("failed to scan trip: %s", strings.ReplaceAll(err.Error(), "\n", " "))
		}

		t["id"] = id
		t["trip_number"] = tripNumber
		t["origin_address"] = originAddress
		t["destination_address"] = destinationAddress
		t["status"] = tripStatus

		if scheduledStart.Valid {
			t["scheduled_start"] = scheduledStart.Time.Format("2006-01-02 15:04:05")
		}
		if cargoDescription.Valid {
			t["cargo_description"] = cargoDescription.String
		}
		if driverFee.Valid {
			t["driver_fee"] = driverFee.Float64
		}

		trips = append(trips, t)
	}

	return trips, nil
}

func UpdateTripStatus(db *sql.DB, tripID int, driverID int, status string) error {
	validStatuses := map[string]bool{
		"started":   true,
		"completed": true,
	}
	if !validStatuses[status] {
		return fmt.Errorf("invalid status: %s", status)
	}

	var query string
	if status == "started" {
		query = `UPDATE trips SET status = $1, actual_start = CURRENT_TIMESTAMP 
				 WHERE id = $2 AND driver_id = $3 AND status = 'assigned'`
	} else {
		query = `UPDATE trips SET status = $1, actual_end = CURRENT_TIMESTAMP 
				 WHERE id = $2 AND driver_id = $3 AND status = 'started'`
	}

	result, err := db.Exec(query, status, tripID, driverID)
	if err != nil {
		return fmt.Errorf("failed to update trip status: %v", err)
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return fmt.Errorf("failed to get rows affected: %v", err)
	}

	if rowsAffected == 0 {
		return fmt.Errorf("trip not found or invalid status transition")
	}

	return nil
}

func RecordTripTracking(db *sql.DB, tripID int, latitude, longitude, speed float64) error {
	// Validate coordinates
	if latitude < -90 || latitude > 90 {
		return fmt.Errorf("invalid latitude: must be between -90 and 90")
	}
	if longitude < -180 || longitude > 180 {
		return fmt.Errorf("invalid longitude: must be between -180 and 180")
	}
	if speed < 0 {
		return fmt.Errorf("invalid speed: must be non-negative")
	}

	query := `INSERT INTO trip_tracking (trip_id, latitude, longitude, speed)
			  VALUES ($1, $2, $3, $4)`

	_, err := db.Exec(query, tripID, latitude, longitude, speed)
	if err != nil {
		return fmt.Errorf("failed to record trip tracking: %v", err)
	}

	return nil
}