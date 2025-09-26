package models

import (
	"time"
)

type GPSRegistration struct {
	ID                 int       `json:"id" db:"id"`
	RegistrationNumber string    `json:"registration_number" db:"registration_number"`
	VehicleType        string    `json:"vehicle_type" db:"vehicle_type"`
	CapacityTons       int       `json:"capacity_tons" db:"capacity_tons"`
	Status             string    `json:"status" db:"status"`
	OperatorNotes      string    `json:"operator_notes" db:"operator_notes"`
	AdminNotes         string    `json:"admin_notes" db:"admin_notes"`
	CreatedAt          time.Time `json:"created_at" db:"created_at"`
	UpdatedAt          time.Time `json:"updated_at" db:"updated_at"`
	ApprovedAt         *time.Time `json:"approved_at" db:"approved_at"`
	ApprovedBy         *int      `json:"approved_by" db:"approved_by"`
}

type GPSRegistrationRequest struct {
	RegistrationNumber string `json:"registration_number" binding:"required"`
	VehicleType        string `json:"vehicle_type" binding:"required"`
	CapacityTons       int    `json:"capacity_tons" binding:"required,min=1"`
	OperatorNotes      string `json:"operator_notes"`
}

type GPSApprovalRequest struct {
	Status     string `json:"status" binding:"required,oneof=approved rejected"`
	AdminNotes string `json:"admin_notes"`
}