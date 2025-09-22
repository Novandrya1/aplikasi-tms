package services

import (
	"testing"
	"time"

	"github.com/youruser/aplikasi-tms/backend/internal/auth"
)

func TestHashPassword(t *testing.T) {
	password := "testpassword123"
	hash, err := HashPassword(password)
	
	if err != nil {
		t.Fatalf("Expected no error, got %v", err)
	}
	
	if len(hash) == 0 {
		t.Fatal("Expected hash to be generated")
	}
	
	if hash == password {
		t.Fatal("Hash should not equal original password")
	}
}

func TestCheckPassword(t *testing.T) {
	password := "testpassword123"
	hash, _ := HashPassword(password)
	
	// Test correct password
	if !CheckPassword(hash, password) {
		t.Fatal("Expected password to match hash")
	}
	
	// Test incorrect password
	if CheckPassword(hash, "wrongpassword") {
		t.Fatal("Expected password to not match hash")
	}
}

func TestGenerateToken(t *testing.T) {
	userID := 1
	username := "testuser"
	role := "user"
	
	token, err := auth.GenerateToken(userID, username, role)
	if err != nil {
		t.Fatalf("Expected no error, got %v", err)
	}
	
	if len(token) == 0 {
		t.Fatal("Expected token to be generated")
	}
}

func TestValidateToken(t *testing.T) {
	userID := 1
	username := "testuser"
	role := "user"
	
	token, err := auth.GenerateToken(userID, username, role)
	if err != nil {
		t.Fatalf("Expected no error generating token, got %v", err)
	}
	
	claims, err := auth.ValidateToken(token)
	if err != nil {
		t.Fatalf("Expected no error, got %v", err)
	}
	
	if claims.UserID != userID {
		t.Fatalf("Expected UserID %d, got %d", userID, claims.UserID)
	}
	
	if claims.Username != username {
		t.Fatalf("Expected Username %s, got %s", username, claims.Username)
	}
	
	if claims.Role != role {
		t.Fatalf("Expected Role %s, got %s", role, claims.Role)
	}
}

func TestValidateExpiredToken(t *testing.T) {
	// This would require modifying token generation to accept custom expiry
	// For now, test with invalid token
	invalidToken := "invalid.token.here"
	
	_, err := auth.ValidateToken(invalidToken)
	if err == nil {
		t.Fatal("Expected error for invalid token")
	}
}