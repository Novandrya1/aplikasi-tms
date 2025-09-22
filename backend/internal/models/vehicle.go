package models

import "time"

type Vehicle struct {
	ID                 int       `json:"id" db:"id"`
	RegistrationNumber string    `json:"registration_number" db:"registration_number"`
	VehicleType        string    `json:"vehicle_type" db:"vehicle_type"`
	Brand              string    `json:"brand" db:"brand"`
	Model              string    `json:"model" db:"model"`
	Year               int       `json:"year" db:"year"`
	ChassisNumber      string    `json:"chassis_number" db:"chassis_number"`
	EngineNumber       string    `json:"engine_number" db:"engine_number"`
	Color              string    `json:"color" db:"color"`
	CapacityWeight     *float64  `json:"capacity_weight" db:"capacity_weight"`
	CapacityVolume     *float64  `json:"capacity_volume" db:"capacity_volume"`
	OwnershipStatus    string    `json:"ownership_status" db:"ownership_status"`
	OperationalStatus  string    `json:"operational_status" db:"operational_status"`
	InsuranceCompany   *string   `json:"insurance_company" db:"insurance_company"`
	InsurancePolicyNumber *string `json:"insurance_policy_number" db:"insurance_policy_number"`
	InsuranceExpiryDate *time.Time `json:"insurance_expiry_date" db:"insurance_expiry_date"`
	LastMaintenanceDate *time.Time `json:"last_maintenance_date" db:"last_maintenance_date"`
	NextMaintenanceDate *time.Time `json:"next_maintenance_date" db:"next_maintenance_date"`
	MaintenanceNotes   *string   `json:"maintenance_notes" db:"maintenance_notes"`
	CreatedBy          int       `json:"created_by" db:"created_by"`
	FleetOwnerID       *int      `json:"fleet_owner_id,omitempty" db:"fleet_owner_id"`
	VerificationStatus string    `json:"verification_status,omitempty" db:"verification_status"`
	CreatedAt          time.Time `json:"created_at" db:"created_at"`
	UpdatedAt          time.Time `json:"updated_at" db:"updated_at"`
}



type VehicleRequest struct {
	RegistrationNumber    string  `json:"registration_number" binding:"required"`
	VehicleType          string  `json:"vehicle_type" binding:"required"`
	Brand                string  `json:"brand" binding:"required"`
	Model                string  `json:"model" binding:"required"`
	Year                 int     `json:"year" binding:"required,min=1900,max=2030"`
	ChassisNumber        string  `json:"chassis_number" binding:"required"`
	EngineNumber         string  `json:"engine_number" binding:"required"`
	Color                string  `json:"color" binding:"required"`
	CapacityWeight       *float64 `json:"capacity_weight"`
	CapacityVolume       *float64 `json:"capacity_volume"`
	OwnershipStatus      string  `json:"ownership_status" binding:"required"`
	OperationalStatus    string  `json:"operational_status"`
	InsuranceCompany     *string `json:"insurance_company"`
	InsurancePolicyNumber *string `json:"insurance_policy_number"`
	InsuranceExpiryDate  *string `json:"insurance_expiry_date" binding:"omitempty,datetime=2006-01-02"`
	LastMaintenanceDate  *string `json:"last_maintenance_date" binding:"omitempty,datetime=2006-01-02"`
	NextMaintenanceDate  *string `json:"next_maintenance_date" binding:"omitempty,datetime=2006-01-02"` 
	MaintenanceNotes     *string `json:"maintenance_notes"`
}

type VehicleResponse struct {
	Vehicle     Vehicle             `json:"vehicle"`
	Attachments []VehicleAttachment `json:"attachments"`
}