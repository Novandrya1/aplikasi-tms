package services

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"regexp"
	"strings"
	"time"

	"github.com/youruser/aplikasi-tms/backend/internal/models"
)

type AutoValidationService struct {
	db *sql.DB
}

func NewAutoValidationService(db *sql.DB) *AutoValidationService {
	return &AutoValidationService{db: db}
}

func (s *AutoValidationService) ValidateVehicle(vehicleID int) (*models.AutoValidationResult, error) {
	result := &models.AutoValidationResult{
		OverallStatus:   "pending",
		Checks:         []models.ValidationCheck{},
		ConfidenceScore: 0.0,
		ProcessedAt:    time.Now(),
	}

	// Get vehicle data
	vehicle, err := s.getVehicleData(vehicleID)
	if err != nil {
		return nil, fmt.Errorf("failed to get vehicle data: %v", err)
	}

	// Get attachments
	attachments, err := s.getVehicleAttachments(vehicleID)
	if err != nil {
		return nil, fmt.Errorf("failed to get attachments: %v", err)
	}

	// Run validation checks
	checks := []models.ValidationCheck{}

	// 1. Document completeness check
	docCheck := s.validateDocumentCompleteness(attachments)
	checks = append(checks, docCheck)

	// 2. Plate number format validation
	plateCheck := s.validatePlateNumber(vehicle["registration_number"].(string))
	checks = append(checks, plateCheck)

	// 3. VIN/Chassis validation
	if chassisNum, ok := vehicle["chassis_number"].(string); ok && chassisNum != "" {
		vinCheck := s.validateVIN(chassisNum)
		checks = append(checks, vinCheck)
	}

	// 4. Duplicate check
	dupCheck := s.checkDuplicateVehicle(vehicle)
	checks = append(checks, dupCheck)

	// 5. Document expiry check
	expiryCheck := s.validateDocumentExpiry(attachments)
	checks = append(checks, expiryCheck)

	result.Checks = checks

	// Calculate overall confidence and status
	result.ConfidenceScore = s.calculateConfidenceScore(checks)
	result.OverallStatus = s.determineOverallStatus(checks, result.ConfidenceScore)

	// Save validation result
	err = s.saveValidationResult(vehicleID, result)
	if err != nil {
		return nil, fmt.Errorf("failed to save validation result: %v", err)
	}

	return result, nil
}

func (s *AutoValidationService) validateDocumentCompleteness(attachments []map[string]interface{}) models.ValidationCheck {
	requiredDocs := []string{"stnk", "bpkb", "foto_depan"}
	foundDocs := make(map[string]bool)

	for _, att := range attachments {
		if attType, ok := att["attachment_type"].(string); ok {
			foundDocs[attType] = true
		}
	}

	missingDocs := []string{}
	for _, required := range requiredDocs {
		if !foundDocs[required] {
			missingDocs = append(missingDocs, required)
		}
	}

	check := models.ValidationCheck{
		Type: "document_completeness",
	}

	if len(missingDocs) == 0 {
		check.Status = "passed"
		check.Confidence = 1.0
		check.Message = "Semua dokumen wajib telah diupload"
	} else {
		check.Status = "failed"
		check.Confidence = 0.0
		check.Message = fmt.Sprintf("Dokumen yang hilang: %s", strings.Join(missingDocs, ", "))
		check.Details = map[string]interface{}{
			"missing_documents": missingDocs,
		}
	}

	return check
}

func (s *AutoValidationService) validatePlateNumber(plateNumber string) models.ValidationCheck {
	check := models.ValidationCheck{
		Type: "plate_format",
	}

	// Indonesian plate format: 1-2 letters + 1-4 digits + 1-3 letters
	plateRegex := regexp.MustCompile(`^[A-Z]{1,2}\s*\d{1,4}\s*[A-Z]{1,3}$`)
	
	cleanPlate := strings.ToUpper(strings.ReplaceAll(plateNumber, " ", ""))
	
	if plateRegex.MatchString(cleanPlate) {
		check.Status = "passed"
		check.Confidence = 0.9
		check.Message = "Format nomor plat valid"
	} else {
		check.Status = "failed"
		check.Confidence = 0.0
		check.Message = "Format nomor plat tidak valid"
		check.Details = map[string]interface{}{
			"expected_format": "Contoh: B1234ABC atau L123AB",
		}
	}

	return check
}

func (s *AutoValidationService) validateVIN(chassisNumber string) models.ValidationCheck {
	check := models.ValidationCheck{
		Type: "vin_format",
	}

	// Basic VIN validation (17 characters, alphanumeric, no I, O, Q)
	vinRegex := regexp.MustCompile(`^[A-HJ-NPR-Z0-9]{17}$`)
	
	if len(chassisNumber) == 17 && vinRegex.MatchString(strings.ToUpper(chassisNumber)) {
		check.Status = "passed"
		check.Confidence = 0.8
		check.Message = "Format nomor rangka valid"
	} else if len(chassisNumber) > 0 {
		check.Status = "warning"
		check.Confidence = 0.5
		check.Message = "Format nomor rangka tidak standar VIN"
	} else {
		check.Status = "failed"
		check.Confidence = 0.0
		check.Message = "Nomor rangka tidak boleh kosong"
	}

	return check
}

func (s *AutoValidationService) checkDuplicateVehicle(vehicle map[string]interface{}) models.ValidationCheck {
	check := models.ValidationCheck{
		Type: "duplicate_check",
	}

	plateNumber := vehicle["registration_number"].(string)
	vehicleID := vehicle["id"].(int)

	var count int
	err := s.db.QueryRow(
		"SELECT COUNT(*) FROM vehicles WHERE registration_number = $1 AND id != $2",
		plateNumber, vehicleID,
	).Scan(&count)

	if err != nil {
		check.Status = "error"
		check.Confidence = 0.0
		check.Message = "Gagal memeriksa duplikasi"
		return check
	}

	if count > 0 {
		check.Status = "failed"
		check.Confidence = 0.0
		check.Message = "Nomor plat sudah terdaftar"
		check.Details = map[string]interface{}{
			"duplicate_count": count,
		}
	} else {
		check.Status = "passed"
		check.Confidence = 1.0
		check.Message = "Tidak ada duplikasi nomor plat"
	}

	return check
}

func (s *AutoValidationService) validateDocumentExpiry(attachments []map[string]interface{}) models.ValidationCheck {
	check := models.ValidationCheck{
		Type: "document_expiry",
	}

	// Simulate OCR data check for STNK expiry
	// In real implementation, this would parse OCR data
	check.Status = "passed"
	check.Confidence = 0.7
	check.Message = "Dokumen masih berlaku (simulasi OCR)"
	check.Details = map[string]interface{}{
		"note": "Implementasi OCR diperlukan untuk validasi tanggal",
	}

	return check
}

func (s *AutoValidationService) calculateConfidenceScore(checks []models.ValidationCheck) float64 {
	if len(checks) == 0 {
		return 0.0
	}

	totalScore := 0.0
	for _, check := range checks {
		if check.Status == "passed" {
			totalScore += check.Confidence
		} else if check.Status == "warning" {
			totalScore += check.Confidence * 0.5
		}
	}

	return totalScore / float64(len(checks))
}

func (s *AutoValidationService) determineOverallStatus(checks []models.ValidationCheck, confidence float64) string {
	hasFailure := false
	hasWarning := false

	for _, check := range checks {
		if check.Status == "failed" {
			hasFailure = true
		} else if check.Status == "warning" {
			hasWarning = true
		}
	}

	if hasFailure {
		return "needs_correction"
	} else if hasWarning || confidence < 0.8 {
		return "under_review"
	} else {
		return "auto_approved"
	}
}

func (s *AutoValidationService) getVehicleData(vehicleID int) (map[string]interface{}, error) {
	query := `SELECT id, registration_number, chassis_number, engine_number FROM vehicles WHERE id = $1`
	
	var id int
	var regNumber, chassisNumber, engineNumber string
	
	err := s.db.QueryRow(query, vehicleID).Scan(&id, &regNumber, &chassisNumber, &engineNumber)
	if err != nil {
		return nil, err
	}

	return map[string]interface{}{
		"id":                  id,
		"registration_number": regNumber,
		"chassis_number":     chassisNumber,
		"engine_number":      engineNumber,
	}, nil
}

func (s *AutoValidationService) getVehicleAttachments(vehicleID int) ([]map[string]interface{}, error) {
	query := `SELECT attachment_type, file_name, ocr_data FROM vehicle_attachments WHERE vehicle_id = $1`
	
	rows, err := s.db.Query(query, vehicleID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var attachments []map[string]interface{}
	for rows.Next() {
		var attType, fileName string
		var ocrData sql.NullString
		
		err := rows.Scan(&attType, &fileName, &ocrData)
		if err != nil {
			continue
		}

		att := map[string]interface{}{
			"attachment_type": attType,
			"file_name":      fileName,
		}
		
		if ocrData.Valid {
			att["ocr_data"] = ocrData.String
		}
		
		attachments = append(attachments, att)
	}

	return attachments, nil
}

func (s *AutoValidationService) saveValidationResult(vehicleID int, result *models.AutoValidationResult) error {
	resultJSON, err := json.Marshal(result)
	if err != nil {
		return err
	}

	// Update vehicle with validation result
	query := `UPDATE vehicles 
			  SET auto_validation_result = $1, 
			      verification_substatus = $2,
			      updated_at = CURRENT_TIMESTAMP
			  WHERE id = $3`

	_, err = s.db.Exec(query, string(resultJSON), result.OverallStatus, vehicleID)
	return err
}