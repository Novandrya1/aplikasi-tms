package services

import (
	"database/sql"
	"fmt"
	"time"

	"github.com/youruser/aplikasi-tms/backend/internal/models"
)

func CreateTrip(db *sql.DB, req models.TripRequest) (*models.Trip, error) {
	// Parse dates if provided
	var departureTime, arrivalTime *time.Time
	if req.DepartureTime != nil && *req.DepartureTime != "" {
		if t, err := time.Parse("2006-01-02T15:04:05Z07:00", *req.DepartureTime); err != nil {
			return nil, fmt.Errorf("invalid departure time format: %v", err)
		} else {
			departureTime = &t
		}
	}
	if req.ArrivalTime != nil && *req.ArrivalTime != "" {
		if t, err := time.Parse("2006-01-02T15:04:05Z07:00", *req.ArrivalTime); err != nil {
			return nil, fmt.Errorf("invalid arrival time format: %v", err)
		} else {
			arrivalTime = &t
		}
	}

	// Set default status
	status := req.Status
	if status == "" {
		status = "planned"
	}

	query := `INSERT INTO trips (driver_id, vehicle_id, origin, destination, 
			  departure_time, arrival_time, status, distance) 
			  VALUES ($1, $2, $3, $4, $5, $6, $7, $8) 
			  RETURNING id, created_at, updated_at`

	var trip models.Trip
	err := db.QueryRow(query, req.DriverID, req.VehicleID, req.Origin, req.Destination,
		departureTime, arrivalTime, status, req.Distance).
		Scan(&trip.ID, &trip.CreatedAt, &trip.UpdatedAt)

	if err != nil {
		return nil, fmt.Errorf("failed to create trip: %v", err)
	}

	trip.DriverID = req.DriverID
	trip.VehicleID = req.VehicleID
	trip.Origin = req.Origin
	trip.Destination = req.Destination
	trip.DepartureTime = departureTime
	trip.ArrivalTime = arrivalTime
	trip.Status = status
	trip.Distance = req.Distance

	return &trip, nil
}

const tripSelectQuery = `SELECT t.id, t.driver_id, t.vehicle_id, t.origin, t.destination,
			  t.departure_time, t.arrival_time, t.status, t.distance,
			  t.created_at, t.updated_at,
			  u.full_name as driver_name, v.registration_number
			  FROM trips t
			  LEFT JOIN drivers d ON t.driver_id = d.id
			  LEFT JOIN users u ON d.user_id = u.id
			  LEFT JOIN vehicles v ON t.vehicle_id = v.id`

func GetTrips(db *sql.DB) ([]models.Trip, error) {
	query := tripSelectQuery + ` ORDER BY t.created_at DESC`

	rows, err := db.Query(query)
	if err != nil {
		return nil, fmt.Errorf("failed to get trips: %v", err)
	}
	defer rows.Close()

	var trips []models.Trip
	for rows.Next() {
		var t models.Trip
		var driverName, vehicleReg sql.NullString
		err := rows.Scan(
			&t.ID, &t.DriverID, &t.VehicleID, &t.Origin, &t.Destination,
			&t.DepartureTime, &t.ArrivalTime, &t.Status, &t.Distance,
			&t.CreatedAt, &t.UpdatedAt, &driverName, &vehicleReg,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan trip: %v", err)
		}

		// Add driver info if available
		if driverName.Valid {
			t.Driver = &models.Driver{
				User: &models.User{FullName: driverName.String},
			}
		}

		// Add vehicle info if available
		if vehicleReg.Valid {
			t.Vehicle = &models.Vehicle{
				RegistrationNumber: vehicleReg.String,
			}
		}

		trips = append(trips, t)
	}

	return trips, nil
}

func GetTripByID(db *sql.DB, id int) (*models.Trip, error) {
	query := tripSelectQuery + ` WHERE t.id = $1`

	var t models.Trip
	var driverName, vehicleReg sql.NullString
	err := db.QueryRow(query, id).Scan(
		&t.ID, &t.DriverID, &t.VehicleID, &t.Origin, &t.Destination,
		&t.DepartureTime, &t.ArrivalTime, &t.Status, &t.Distance,
		&t.CreatedAt, &t.UpdatedAt, &driverName, &vehicleReg,
	)

	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("trip not found")
		}
		return nil, fmt.Errorf("failed to get trip: %v", err)
	}

	// Add driver info if available
	if driverName.Valid {
		t.Driver = &models.Driver{
			User: &models.User{FullName: driverName.String},
		}
	}

	// Add vehicle info if available
	if vehicleReg.Valid {
		t.Vehicle = &models.Vehicle{
			RegistrationNumber: vehicleReg.String,
		}
	}

	return &t, nil
}