package models

type DashboardStats struct {
	TotalVehicles    int     `json:"total_vehicles"`
	ActiveVehicles   int     `json:"active_vehicles"`
	TotalDrivers     int     `json:"total_drivers"`
	ActiveDrivers    int     `json:"active_drivers"`
	TotalTrips       int     `json:"total_trips"`
	OngoingTrips     int     `json:"ongoing_trips"`
	CompletedTrips   int     `json:"completed_trips"`
	TotalDistance    float64 `json:"total_distance"`
	MaintenanceDue   int     `json:"maintenance_due"`
}

type VehicleUtilization struct {
	VehicleID        int     `json:"vehicle_id"`
	RegistrationNumber string `json:"registration_number"`
	TotalTrips       int     `json:"total_trips"`
	TotalDistance    float64 `json:"total_distance"`
	UtilizationRate  float64 `json:"utilization_rate"`
}