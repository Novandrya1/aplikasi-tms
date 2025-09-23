package models

import "time"

type Vehicle struct {
	ID                    int        `json:"id" db:"id"`
	RegistrationNumber    string     `json:"registration_number" db:"registration_number"`
	VehicleType          string     `json:"vehicle_type" db:"vehicle_type"`
	Brand                string     `json:"brand" db:"brand"`
	Model                string     `json:"model" db:"model"`
	Year                 int        `json:"year" db:"year"`
	ChassisNumber        string     `json:"chassis_number" db:"chassis_number"`
	EngineNumber         string     `json:"engine_number" db:"engine_number"`
	Color                string     `json:"color" db:"color"`
	CapacityWeight       *float64   `json:"capacity_weight" db:"capacity_weight"`
	CapacityVolume       *float64   `json:"capacity_volume" db:"capacity_volume"`
	OwnershipStatus      string     `json:"ownership_status" db:"ownership_status"`
	OperationalStatus    string     `json:"operational_status" db:"operational_status"`
	VerificationStatus   string     `json:"verification_status" db:"verification_status"`
	VerificationSubstatus string    `json:"verification_substatus" db:"verification_substatus"`
	AutoValidationResult *string    `json:"auto_validation_result" db:"auto_validation_result"`
	VerificationNotes    *string    `json:"verification_notes" db:"verification_notes"`
	RequiresInspection   bool       `json:"requires_inspection" db:"requires_inspection"`
	InspectionScheduledAt *time.Time `json:"inspection_scheduled_at" db:"inspection_scheduled_at"`
	VerifiedBy           *int       `json:"verified_by" db:"verified_by"`
	VerifiedAt           *time.Time `json:"verified_at" db:"verified_at"`
	InsuranceCompany     *string    `json:"insurance_company" db:"insurance_company"`
	InsurancePolicyNumber *string   `json:"insurance_policy_number" db:"insurance_policy_number"`
	InsuranceExpiryDate  *time.Time `json:"insurance_expiry_date" db:"insurance_expiry_date"`
	LastMaintenanceDate  *time.Time `json:"last_maintenance_date" db:"last_maintenance_date"`
	NextMaintenanceDate  *time.Time `json:"next_maintenance_date" db:"next_maintenance_date"`
	MaintenanceNotes     *string    `json:"maintenance_notes" db:"maintenance_notes"`
	CreatedBy            int        `json:"created_by" db:"created_by"`
	FleetOwnerID         *int       `json:"fleet_owner_id" db:"fleet_owner_id"`
	CreatedAt            time.Time  `json:"created_at" db:"created_at"`
	UpdatedAt            time.Time  `json:"updated_at" db:"updated_at"`
}

type VehicleInspection struct {
	ID             int        `json:"id" db:"id"`
	VehicleID      int        `json:"vehicle_id" db:"vehicle_id"`
	InspectorID    *int       `json:"inspector_id" db:"inspector_id"`
	InspectionType string     `json:"inspection_type" db:"inspection_type"`
	ChecklistData  *string    `json:"checklist_data" db:"checklist_data"`
	Photos         *string    `json:"photos" db:"photos"`
	Result         string     `json:"result" db:"result"`
	Notes          *string    `json:"notes" db:"notes"`
	ScheduledAt    *time.Time `json:"scheduled_at" db:"scheduled_at"`
	CompletedAt    *time.Time `json:"completed_at" db:"completed_at"`
	CreatedAt      time.Time  `json:"created_at" db:"created_at"`
}

type AutoValidationResult struct {
	OverallStatus   string            `json:"overall_status"`
	Checks         []ValidationCheck `json:"checks"`
	ConfidenceScore float64          `json:"confidence_score"`
	ProcessedAt    time.Time        `json:"processed_at"`
}

type ValidationCheck struct {
	Type       string                 `json:"type"`
	Status     string                 `json:"status"`
	Confidence float64                `json:"confidence"`
	Message    string                 `json:"message"`
	Details    map[string]interface{} `json:"details,omitempty"`
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



type VehicleAttachment struct {
	ID               int       `json:"id" db:"id"`
	VehicleID        int       `json:"vehicle_id" db:"vehicle_id"`
	AttachmentType   string    `json:"attachment_type" db:"attachment_type"`
	FileName         string    `json:"file_name" db:"file_name"`
	FilePath         string    `json:"file_path" db:"file_path"`
	FileSize         int       `json:"file_size" db:"file_size"`
	MimeType         string    `json:"mime_type" db:"mime_type"`
	OCRData          *string   `json:"ocr_data" db:"ocr_data"`
	ValidationStatus string    `json:"validation_status" db:"validation_status"`
	ValidationErrors []string  `json:"validation_errors" db:"validation_errors"`
	UploadedAt       time.Time `json:"uploaded_at" db:"uploaded_at"`
}

type VehicleResponse struct {
	Vehicle          Vehicle               `json:"vehicle"`
	Attachments      []VehicleAttachment   `json:"attachments"`
	Inspections      []VehicleInspection   `json:"inspections,omitempty"`
	CrossCheckResults []CrossCheckResult   `json:"cross_check_results,omitempty"`
	OwnerInfo        *FleetOwnerInfo       `json:"owner_info,omitempty"`
}

// Enhanced verification request
type VehicleVerificationRequest struct {
	Status           string                 `json:"status" binding:"required"`
	Notes            string                 `json:"notes"`
	CorrectionItems  []string               `json:"correction_items,omitempty"`
	RequiresInspection bool                 `json:"requires_inspection"`
	ValidationChecks map[string]interface{} `json:"validation_checks,omitempty"`
}

// Cross-check results
type CrossCheckResult struct {
	CheckType    string                 `json:"check_type"`
	Status       string                 `json:"status"`
	Message      string                 `json:"message"`
	Details      map[string]interface{} `json:"details,omitempty"`
	CheckedAt    time.Time              `json:"checked_at"`
}

type FleetOwnerInfo struct {
	ID              int    `json:"id"`
	CompanyName     string `json:"company_name"`
	BusinessLicense string `json:"business_license"`
	Address         string `json:"address"`
	Phone           string `json:"phone"`
	Email           string `json:"email"`
	OwnerName       string `json:"owner_name"`
	KTPNumber       string `json:"ktp_number"`
	NPWP            string `json:"npwp"`
	OwnerType       string `json:"owner_type"` // "individual" or "company"
	Verified        bool   `json:"verified"`
}

// Admin verification dashboard models
type AdminVerificationDashboard struct {
	PendingCount      int                    `json:"pending_count"`
	NeedsCorrectionCount int                 `json:"needs_correction_count"`
	UnderReviewCount  int                    `json:"under_review_count"`
	ApprovedToday     int                    `json:"approved_today"`
	RejectedToday     int                    `json:"rejected_today"`
	RecentSubmissions []VehicleSubmission    `json:"recent_submissions"`
	UrgentItems       []UrgentVerificationItem `json:"urgent_items"`
}

type VehicleSubmission struct {
	ID               int    `json:"id"`
	RegistrationNumber string `json:"registration_number"`
	CompanyName      string `json:"company_name"`
	OwnerName        string `json:"owner_name"`
	OwnerType        string `json:"owner_type"`
	Status           string `json:"status"`
	Substatus        string `json:"substatus"`
	SubmittedAt      string `json:"submitted_at"`
	DaysWaiting      int    `json:"days_waiting"`
	Priority         string `json:"priority"`
}

type UrgentVerificationItem struct {
	VehicleID        int    `json:"vehicle_id"`
	RegistrationNumber string `json:"registration_number"`
	UrgencyType      string `json:"urgency_type"`
	Message          string `json:"message"`
	DaysOverdue      int    `json:"days_overdue"`
}

// Notification models for verification workflow
type VerificationNotification struct {
	ID          int                    `json:"id"`
	VehicleID   int                    `json:"vehicle_id"`
	UserID      int                    `json:"user_id"`
	Type        string                 `json:"type"`
	Title       string                 `json:"title"`
	Message     string                 `json:"message"`
	Data        map[string]interface{} `json:"data,omitempty"`
	Read        bool                   `json:"read"`
	CreatedAt   time.Time              `json:"created_at"`
}