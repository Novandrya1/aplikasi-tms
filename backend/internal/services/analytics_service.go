package services

import (
	"database/sql"
	"fmt"
	"log"

	"github.com/youruser/aplikasi-tms/backend/internal/middleware"
	"github.com/youruser/aplikasi-tms/backend/internal/models"
)

// Constants for better maintainability
const (
	DaysInMonth = 30.0
)

func GetDashboardStats(db *sql.DB) (*models.DashboardStats, error) {
	var stats models.DashboardStats

	// Single optimized query to get all stats at once
	query := `
		SELECT 
			(SELECT COUNT(*) FROM vehicles) as total_vehicles,
			(SELECT COUNT(*) FROM vehicles WHERE operational_status = 'active') as active_vehicles,
			(SELECT COUNT(*) FROM drivers) as total_drivers,
			(SELECT COUNT(*) FROM drivers WHERE status = 'available') as active_drivers,
			(SELECT COUNT(*) FROM trips) as total_trips,
			(SELECT COUNT(*) FROM trips WHERE status IN ('ongoing', 'in_progress')) as ongoing_trips,
			(SELECT COUNT(*) FROM trips WHERE status = 'completed') as completed_trips,
			(SELECT COALESCE(SUM(distance), 0) FROM trips WHERE distance IS NOT NULL) as total_distance,
			(SELECT COUNT(*) FROM vehicles WHERE next_maintenance_date <= CURRENT_DATE AND next_maintenance_date IS NOT NULL) as maintenance_due
	`

	err := db.QueryRow(query).Scan(
		&stats.TotalVehicles,
		&stats.ActiveVehicles,
		&stats.TotalDrivers,
		&stats.ActiveDrivers,
		&stats.TotalTrips,
		&stats.OngoingTrips,
		&stats.CompletedTrips,
		&stats.TotalDistance,
		&stats.MaintenanceDue,
	)
	if err != nil {
		return nil, fmt.Errorf("failed to get dashboard stats: %v", err)
	}

	return &stats, nil
}

func GetVehicleUtilization(db *sql.DB) ([]models.VehicleUtilization, error) {
	query := `SELECT v.id, v.registration_number, 
			  COUNT(t.id) as total_trips,
			  COALESCE(SUM(t.distance), 0) as total_distance,
			  CASE 
			    WHEN COUNT(t.id) > 0 THEN (COUNT(t.id)::float / $1) * 100 
			    ELSE 0 
			  END as utilization_rate
			  FROM vehicles v
			  LEFT JOIN trips t ON v.id = t.vehicle_id
			  GROUP BY v.id, v.registration_number
			  ORDER BY total_trips DESC`

	rows, err := db.Query(query, DaysInMonth)
	if err != nil {
		return nil, fmt.Errorf("failed to get vehicle utilization: %v", err)
	}
	defer rows.Close()

	var utilizations []models.VehicleUtilization
	for rows.Next() {
		var u models.VehicleUtilization
		err := rows.Scan(&u.VehicleID, &u.RegistrationNumber, &u.TotalTrips, &u.TotalDistance, &u.UtilizationRate)
		if err != nil {
			log.Printf("Error scanning vehicle utilization: %v", middleware.SanitizeForLog(err.Error()))
			return nil, fmt.Errorf("failed to scan vehicle utilization: %v", err)
		}
		utilizations = append(utilizations, u)
	}

	// Check for errors during iteration
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("error during row iteration: %v", err)
	}

	return utilizations, nil
}