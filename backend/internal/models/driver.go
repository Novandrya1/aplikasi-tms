package models

import "time"

type Driver struct {
	ID             int        `json:"id"`
	UserID         int        `json:"user_id"`
	LicenseNumber  string     `json:"license_number"`
	LicenseExpiry  time.Time  `json:"license_expiry"`
	Status         string     `json:"status"`
	CreatedAt      time.Time  `json:"created_at"`
	UpdatedAt      time.Time  `json:"updated_at"`
	// Relations
	User           *User      `json:"user,omitempty"`
}

type DriverRequest struct {
	UserID         int    `json:"user_id" binding:"required"`
	LicenseNumber  string `json:"license_number" binding:"required"`
	LicenseExpiry  string `json:"license_expiry" binding:"required,datetime=2006-01-02"`
	Status         string `json:"status,omitempty"`
}