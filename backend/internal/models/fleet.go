package models

import "time"

type FleetOwner struct {
	ID             int       `json:"id"`
	UserID         int       `json:"user_id"`
	CompanyName    string    `json:"company_name"`
	BusinessLicense string   `json:"business_license"`
	Address        string    `json:"address"`
	Phone          string    `json:"phone"`
	Verified       bool      `json:"verified"`
	CreatedAt      time.Time `json:"created_at"`
	UpdatedAt      time.Time `json:"updated_at"`
	User           *User     `json:"user,omitempty"`
}

type FleetOwnerRequest struct {
	CompanyName     string `json:"company_name" binding:"required"`
	BusinessLicense string `json:"business_license"`
	Address         string `json:"address" binding:"required"`
	PhoneNumber     string `json:"phone_number" binding:"required"`
	Email           string `json:"email" binding:"required,email"`
}



type VehicleRegistrationRequest struct {
	// Basic Info
	RegistrationNumber string `json:"registration_number" binding:"required"`
	VehicleType        string `json:"vehicle_type" binding:"required"`
	Brand              string `json:"brand" binding:"required"`
	Model              string `json:"model" binding:"required"`
	Year               int    `json:"year" binding:"required"`
	
	// Technical Info
	ChassisNumber      string  `json:"chassis_number" binding:"required"`
	EngineNumber       string  `json:"engine_number" binding:"required"`
	Color              string  `json:"color" binding:"required"`
	CapacityWeight     *float64 `json:"capacity_weight"`
	CapacityVolume     *float64 `json:"capacity_volume"`
	
	// Ownership & Status
	OwnershipStatus    string `json:"ownership_status" binding:"required"`
	OperationalStatus  string `json:"operational_status"`
	
	// Insurance Info
	InsuranceCompany       string `json:"insurance_company"`
	InsurancePolicyNumber  string `json:"insurance_policy_number"`
	InsuranceExpiryDate    *string `json:"insurance_expiry_date"`
	
	// Maintenance Info
	LastMaintenanceDate    *string `json:"last_maintenance_date"`
	NextMaintenanceDate    *string `json:"next_maintenance_date"`
	MaintenanceNotes       string  `json:"maintenance_notes"`
	
	// Attachments (file uploads will be handled separately)
	Attachments []string `json:"attachments,omitempty"`
}