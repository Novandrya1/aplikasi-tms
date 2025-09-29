package models

import "time"

type GPSDevice struct {
	ID               int       `json:"id"`
	DeviceID         string    `json:"device_id"`
	VehicleID        *int      `json:"vehicle_id"`
	RegistrationID   int       `json:"registration_id"`
	Status           string    `json:"status"` // pending_installation, installed, active, inactive
	InstalledDate    *time.Time `json:"installed_date"`
	LastSignal       *time.Time `json:"last_signal"`
	CreatedAt        time.Time `json:"created_at"`
	UpdatedAt        time.Time `json:"updated_at"`
}

type GPSTrackingData struct {
	ID        int     `json:"id"`
	DeviceID  string  `json:"device_id"`
	Latitude  float64 `json:"latitude"`
	Longitude float64 `json:"longitude"`
	Speed     float64 `json:"speed"`
	Timestamp time.Time `json:"timestamp"`
}