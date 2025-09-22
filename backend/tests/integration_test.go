package tests

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
	"github.com/youruser/aplikasi-tms/backend/internal/auth"
)

func setupTestRouter() *gin.Engine {
	gin.SetMode(gin.TestMode)
	router := gin.Default()
	
	api := router.Group("/api/v1")
	{
		api.POST("/auth/login", testLoginHandler)
		api.GET("/health", testHealthHandler)
	}
	
	return router
}

func testHealthHandler(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"status":  "ok",
		"message": "TMS Backend is running",
	})
}

func testLoginHandler(c *gin.Context) {
	var req struct {
		Email    string `json:"email"`
		Password string `json:"password"`
	}
	
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request"})
		return
	}
	
	if req.Email == "test@tms.com" && req.Password == "password" {
		token, _ := auth.GenerateToken(1, "testuser", "user")
		c.JSON(http.StatusOK, gin.H{
			"token": token,
			"user": gin.H{
				"id":        1,
				"username":  "testuser",
				"email":     "test@tms.com",
				"full_name": "Test User",
				"role":      "user",
			},
		})
	} else {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid credentials"})
	}
}

func TestHealthEndpoint(t *testing.T) {
	router := setupTestRouter()
	
	req, _ := http.NewRequest("GET", "/api/v1/health", nil)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)
	
	if w.Code != http.StatusOK {
		t.Fatalf("Expected status 200, got %d", w.Code)
	}
	
	var response map[string]interface{}
	json.Unmarshal(w.Body.Bytes(), &response)
	
	if response["status"] != "ok" {
		t.Fatal("Expected status to be 'ok'")
	}
}

func TestLoginEndpoint(t *testing.T) {
	router := setupTestRouter()
	
	loginData := map[string]string{
		"email":    "test@tms.com",
		"password": "password",
	}
	
	jsonData, _ := json.Marshal(loginData)
	req, _ := http.NewRequest("POST", "/api/v1/auth/login", bytes.NewBuffer(jsonData))
	req.Header.Set("Content-Type", "application/json")
	
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)
	
	if w.Code != http.StatusOK {
		t.Fatalf("Expected status 200, got %d", w.Code)
	}
	
	var response map[string]interface{}
	json.Unmarshal(w.Body.Bytes(), &response)
	
	if response["token"] == nil {
		t.Fatal("Expected token in response")
	}
}