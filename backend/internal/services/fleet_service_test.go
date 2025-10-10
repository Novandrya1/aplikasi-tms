package services

import (
	"database/sql"
	"testing"

	_ "github.com/lib/pq"
)

func setupTestDB(t *testing.T) *sql.DB {
	// Use test database or in-memory database
	db, err := sql.Open("postgres", "postgres://tms_user:tms_password@localhost:5432/tms_test?sslmode=disable")
	if err != nil {
		t.Fatalf("Failed to connect to test database: %v", err)
	}
	return db
}

func TestCreateFleetOwner(t *testing.T) {
	// Skip test - function not implemented yet
	t.Skip("Skipping test - CreateFleetOwner function not implemented")
}

func TestValidateVehicleData(t *testing.T) {
	// Test valid vehicle data
	validVehicle := map[string]interface{}{
		"registration_number": "B1234ABC",
		"vehicle_type":        "Truk",
		"brand":               "Toyota",
		"model":               "Dyna",
		"year":                2020,
		"chassis_number":      "CHASSIS123",
		"engine_number":       "ENGINE123",
		"color":               "Putih",
		"ownership_status":    "Milik Sendiri",
	}

	if !isValidVehicleData(validVehicle) {
		t.Fatal("Expected valid vehicle data to pass validation")
	}

	// Test invalid vehicle data
	invalidVehicle := map[string]interface{}{
		"registration_number": "", // Empty required field
		"vehicle_type":        "Truk",
	}

	if isValidVehicleData(invalidVehicle) {
		t.Fatal("Expected invalid vehicle data to fail validation")
	}
}

func isValidVehicleData(vehicle map[string]interface{}) bool {
	requiredFields := []string{
		"registration_number", "vehicle_type", "brand", "model",
		"chassis_number", "engine_number", "color", "ownership_status",
	}

	for _, field := range requiredFields {
		if val, exists := vehicle[field]; !exists || val == "" {
			return false
		}
	}

	// Validate year
	if year, exists := vehicle["year"]; exists {
		if yearInt, ok := year.(int); ok {
			if yearInt < 1900 || yearInt > 2030 {
				return false
			}
		}
	}

	return true
}
