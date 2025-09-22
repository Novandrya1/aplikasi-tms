package services

import (
	"encoding/base64"
	"fmt"
	"regexp"
	"strings"
	"time"
)

type OCRService struct{}

type STNKData struct {
	PlateNumber    string                 `json:"plate_number"`
	OwnerName      string                 `json:"owner_name"`
	NIK            string                 `json:"nik"`
	Address        string                 `json:"address"`
	VehicleBrand   string                 `json:"vehicle_brand"`
	VehicleModel   string                 `json:"vehicle_model"`
	VehicleYear    string                 `json:"vehicle_year"`
	ChassisNumber  string                 `json:"chassis_number"`
	EngineNumber   string                 `json:"engine_number"`
	VehicleColor   string                 `json:"vehicle_color"`
	ExpiryDate     string                 `json:"expiry_date"`
	IssueDate      string                 `json:"issue_date"`
	ConfidenceScore float64               `json:"confidence_score"`
	ExtractedFields []ExtractedField      `json:"extracted_fields"`
}

type KTPData struct {
	NIK           string  `json:"nik"`
	Name          string  `json:"name"`
	BirthPlace    string  `json:"birth_place"`
	BirthDate     string  `json:"birth_date"`
	Gender        string  `json:"gender"`
	Address       string  `json:"address"`
	RTRW          string  `json:"rt_rw"`
	Village       string  `json:"village"`
	District      string  `json:"district"`
	City          string  `json:"city"`
	Province      string  `json:"province"`
	Religion      string  `json:"religion"`
	MaritalStatus string  `json:"marital_status"`
	Occupation    string  `json:"occupation"`
	Nationality   string  `json:"nationality"`
	ExpiryDate    string  `json:"expiry_date"`
	ConfidenceScore float64 `json:"confidence_score"`
}

type ExtractedField struct {
	Field      string  `json:"field"`
	Value      string  `json:"value"`
	Confidence float64 `json:"confidence"`
}

type FaceMatchResult struct {
	MatchScore   float64                `json:"match_score"`
	IsMatch      bool                   `json:"is_match"`
	Confidence   string                 `json:"confidence"`
	Threshold    float64                `json:"threshold"`
	Details      map[string]interface{} `json:"details"`
}

type QualityResult struct {
	OverallQuality string                 `json:"overall_quality"`
	QualityScore   float64                `json:"quality_score"`
	Issues         []string               `json:"issues"`
	Recommendations []string              `json:"recommendations"`
	Checks         map[string]interface{} `json:"checks"`
}

func NewOCRService() *OCRService {
	return &OCRService{}
}

// ExtractSTNKData extracts data from STNK image
func (s *OCRService) ExtractSTNKData(base64Image string) (*STNKData, error) {
	// Validate base64 image
	if !s.isValidBase64Image(base64Image) {
		return nil, fmt.Errorf("invalid base64 image format")
	}

	// For demo purposes, return mock data with some randomization
	// In production, this would call actual OCR service (Google Vision, AWS Textract, etc.)
	
	mockData := &STNKData{
		PlateNumber:    s.generateMockPlateNumber(),
		OwnerName:      "AHMAD SURYANTO",
		NIK:            "3201234567890123",
		Address:        "JL. MERDEKA NO. 123, JAKARTA",
		VehicleBrand:   "TOYOTA",
		VehicleModel:   "AVANZA",
		VehicleYear:    "2020",
		ChassisNumber:  "MHKA1BA1HKK123456",
		EngineNumber:   "3SZ1234567",
		VehicleColor:   "HITAM",
		ExpiryDate:     "2025-12-31",
		IssueDate:      "2020-01-15",
		ConfidenceScore: 0.92,
		ExtractedFields: []ExtractedField{
			{Field: "plate_number", Value: "L1234AB", Confidence: 0.95},
			{Field: "owner_name", Value: "AHMAD SURYANTO", Confidence: 0.90},
			{Field: "nik", Value: "3201234567890123", Confidence: 0.88},
			{Field: "expiry_date", Value: "2025-12-31", Confidence: 0.93},
		},
	}

	return mockData, nil
}

// ExtractKTPData extracts data from KTP image
func (s *OCRService) ExtractKTPData(base64Image string) (*KTPData, error) {
	if !s.isValidBase64Image(base64Image) {
		return nil, fmt.Errorf("invalid base64 image format")
	}

	mockData := &KTPData{
		NIK:           "3201234567890123",
		Name:          "AHMAD SURYANTO",
		BirthPlace:    "JAKARTA",
		BirthDate:     "1985-05-15",
		Gender:        "LAKI-LAKI",
		Address:       "JL. MERDEKA NO. 123",
		RTRW:          "001/002",
		Village:       "MENTENG",
		District:      "MENTENG",
		City:          "JAKARTA PUSAT",
		Province:      "DKI JAKARTA",
		Religion:      "ISLAM",
		MaritalStatus: "KAWIN",
		Occupation:    "KARYAWAN SWASTA",
		Nationality:   "WNI",
		ExpiryDate:    "2030-05-15",
		ConfidenceScore: 0.89,
	}

	return mockData, nil
}

// PerformFaceMatch compares selfie with KTP photo
func (s *OCRService) PerformFaceMatch(selfieBase64, ktpBase64 string) (*FaceMatchResult, error) {
	if !s.isValidBase64Image(selfieBase64) || !s.isValidBase64Image(ktpBase64) {
		return nil, fmt.Errorf("invalid base64 image format")
	}

	// Mock face matching result
	result := &FaceMatchResult{
		MatchScore: 0.87,
		IsMatch:    true,
		Confidence: "high",
		Threshold:  0.75,
		Details: map[string]interface{}{
			"face_detected_selfie":   true,
			"face_detected_ktp":      true,
			"quality_score_selfie":   0.92,
			"quality_score_ktp":      0.85,
		},
	}

	return result, nil
}

// ValidateDocumentQuality checks image quality and readability
func (s *OCRService) ValidateDocumentQuality(base64Image, documentType string) (*QualityResult, error) {
	if !s.isValidBase64Image(base64Image) {
		return nil, fmt.Errorf("invalid base64 image format")
	}

	result := &QualityResult{
		OverallQuality: "good",
		QualityScore:   0.88,
		Issues:         []string{},
		Recommendations: []string{},
		Checks: map[string]interface{}{
			"brightness": map[string]interface{}{
				"score":  0.90,
				"status": "good",
			},
			"blur": map[string]interface{}{
				"score":  0.85,
				"status": "good",
			},
			"contrast": map[string]interface{}{
				"score":  0.92,
				"status": "excellent",
			},
			"text_readability": map[string]interface{}{
				"score":  0.87,
				"status": "good",
			},
			"document_bounds": map[string]interface{}{
				"score":  0.95,
				"status": "excellent",
			},
		},
	}

	// Add quality issues based on checks
	if result.QualityScore < 0.7 {
		result.Issues = append(result.Issues, "Low overall image quality")
		result.Recommendations = append(result.Recommendations, "Please retake photo with better lighting")
	}

	return result, nil
}

// ValidateSTNKData performs business rule validation on extracted STNK data
func (s *OCRService) ValidateSTNKData(data *STNKData) []string {
	var issues []string

	// Check expiry date
	if expiryDate, err := time.Parse("2006-01-02", data.ExpiryDate); err == nil {
		if expiryDate.Before(time.Now().AddDate(0, 0, 14)) {
			issues = append(issues, "STNK akan habis dalam 14 hari atau sudah expired")
		}
	}

	// Validate plate number format
	plateRegex := regexp.MustCompile(`^[A-Z]{1,2}\s?\d{1,4}\s?[A-Z]{1,3}$`)
	if !plateRegex.MatchString(data.PlateNumber) {
		issues = append(issues, "Format nomor polisi tidak valid")
	}

	// Validate NIK format (16 digits)
	nikRegex := regexp.MustCompile(`^\d{16}$`)
	if !nikRegex.MatchString(data.NIK) {
		issues = append(issues, "Format NIK tidak valid (harus 16 digit)")
	}

	// Check confidence score
	if data.ConfidenceScore < 0.8 {
		issues = append(issues, "Kualitas gambar kurang jelas, confidence score rendah")
	}

	return issues
}

// ValidateKTPData performs business rule validation on extracted KTP data
func (s *OCRService) ValidateKTPData(data *KTPData) []string {
	var issues []string

	// Validate NIK format
	nikRegex := regexp.MustCompile(`^\d{16}$`)
	if !nikRegex.MatchString(data.NIK) {
		issues = append(issues, "Format NIK tidak valid (harus 16 digit)")
	}

	// Check if KTP is expired
	if expiryDate, err := time.Parse("2006-01-02", data.ExpiryDate); err == nil {
		if expiryDate.Before(time.Now()) {
			issues = append(issues, "KTP sudah expired")
		}
	}

	// Check confidence score
	if data.ConfidenceScore < 0.8 {
		issues = append(issues, "Kualitas gambar KTP kurang jelas")
	}

	return issues
}

// Helper functions
func (s *OCRService) isValidBase64Image(base64Str string) bool {
	if !strings.HasPrefix(base64Str, "data:image/") {
		return false
	}
	
	parts := strings.Split(base64Str, ",")
	if len(parts) != 2 {
		return false
	}
	
	_, err := base64.StdEncoding.DecodeString(parts[1])
	return err == nil
}

func (s *OCRService) generateMockPlateNumber() string {
	// Generate random plate number for demo
	prefixes := []string{"L", "B", "D", "F", "N", "AA", "AB"}
	numbers := []string{"1234", "5678", "9012", "3456"}
	suffixes := []string{"AB", "CD", "EF", "GH", "XY"}
	
	prefix := prefixes[time.Now().Second()%len(prefixes)]
	number := numbers[time.Now().Minute()%len(numbers)]
	suffix := suffixes[time.Now().Hour()%len(suffixes)]
	
	return fmt.Sprintf("%s%s%s", prefix, number, suffix)
}

// CrossValidateData compares STNK and KTP data for consistency
func (s *OCRService) CrossValidateData(stnkData *STNKData, ktpData *KTPData) []string {
	var issues []string

	// Check if NIK matches
	if stnkData.NIK != ktpData.NIK {
		issues = append(issues, "NIK pada STNK tidak sesuai dengan KTP")
	}

	// Check if name matches (case insensitive)
	if strings.ToUpper(stnkData.OwnerName) != strings.ToUpper(ktpData.Name) {
		issues = append(issues, "Nama pemilik pada STNK tidak sesuai dengan KTP")
	}

	return issues
}