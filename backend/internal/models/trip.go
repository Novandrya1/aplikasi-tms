package models

import "time"

type Trip struct {
	ID            int        `json:"id"`
	DriverID      *int       `json:"driver_id"`
	VehicleID     *int       `json:"vehicle_id"`
	Origin        string     `json:"origin"`
	Destination   string     `json:"destination"`
	DepartureTime *time.Time `json:"departure_time"`
	ArrivalTime   *time.Time `json:"arrival_time"`
	Status        string     `json:"status"`
	Distance      *float64   `json:"distance"`
	CreatedAt     time.Time  `json:"created_at"`
	UpdatedAt     time.Time  `json:"updated_at"`
	// Relations
	Driver        *Driver    `json:"driver,omitempty"`
	Vehicle       *Vehicle   `json:"vehicle,omitempty"`
}

type TripRequest struct {
	DriverID      *int    `json:"driver_id"`
	VehicleID     *int    `json:"vehicle_id"`
	Origin        string  `json:"origin" binding:"required"`
	Destination   string  `json:"destination" binding:"required"`
	DepartureTime *string `json:"departure_time" binding:"omitempty,datetime=2006-01-02T15:04:05Z07:00"`
	ArrivalTime   *string `json:"arrival_time" binding:"omitempty,datetime=2006-01-02T15:04:05Z07:00"`
	Status        string  `json:"status,omitempty"`
	Distance      *float64 `json:"distance"`
}