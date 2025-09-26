package main

import (
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
	"github.com/youruser/aplikasi-tms/backend/internal/db"
	"github.com/youruser/aplikasi-tms/backend/internal/auth"
	"github.com/youruser/aplikasi-tms/backend/internal/middleware"
	"github.com/youruser/aplikasi-tms/backend/internal/models"
	"github.com/youruser/aplikasi-tms/backend/internal/services"
	"github.com/youruser/aplikasi-tms/backend/internal/repository"
)

func main() {
	// Load environment variables
	if err := godotenv.Load(); err != nil {
		log.Println("No .env file found")
	}

	// Initialize Gin router
	r := gin.Default()

	// CORS middleware with security headers
	allowedOrigins := os.Getenv("ALLOWED_ORIGINS")
	if allowedOrigins == "" {
		allowedOrigins = "http://localhost:3000,http://localhost:3001,http://localhost:3005,http://localhost:3006,http://localhost:4000,http://0.0.0.0:3005"
	}
	
	// Simple CORS - allow all
	r.Use(func(c *gin.Context) {
		c.Header("Access-Control-Allow-Origin", "*")
		c.Header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		c.Header("Access-Control-Allow-Headers", "*")
		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}
		c.Next()
	})

	// Security headers middleware
	r.Use(func(c *gin.Context) {
		c.Header("X-Content-Type-Options", "nosniff")
		c.Header("X-Frame-Options", "DENY")
		c.Header("X-XSS-Protection", "1; mode=block")
		c.Header("Referrer-Policy", "strict-origin-when-cross-origin")
		c.Next()
	})
	
	// CSRF Protection disabled for development
	// Will be enabled per-endpoint basis for sensitive operations
	
	// Performance middleware disabled for debugging

	// Health check endpoint
	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status": "ok",
			"message": "TMS Backend is running",
		})
	})

	// API routes
	api := r.Group("/api/v1")
	{
		api.GET("/ping", func(c *gin.Context) {
			c.JSON(http.StatusOK, gin.H{
				"message": "pong",
			})
		})
		
		api.GET("/db-status", func(c *gin.Context) {
			conn, err := db.Connect()
			if err != nil {
				log.Printf("Database connection error: %v", middleware.SanitizeForLog(err.Error()))
				c.JSON(http.StatusInternalServerError, gin.H{
					"status": "error",
					"message": "Database connection failed",
				})
				return
			}
			defer conn.Close()
			
			var count int
			query := "SELECT COUNT(*) FROM users"
			err = conn.QueryRow(query).Scan(&count)
			if err != nil {
				log.Printf("Database query error: %v", middleware.SanitizeForLog(err.Error()))
				c.JSON(http.StatusInternalServerError, gin.H{
					"status": "error",
					"message": "Database query failed",
				})
				return
			}
			
			c.JSON(http.StatusOK, gin.H{
				"status": "ok",
				"message": "Database connected successfully",
				"users_count": count,
			})
		})
		
		api.POST("/register", registerHandler)
		api.POST("/login", loginHandler)
		
		// Vehicle endpoints
		api.POST("/vehicles", middleware.AuthRequired(), createVehicleHandler)
		api.GET("/approved-vehicles", getApprovedVehiclesPublicHandler)
		api.GET("/vehicles", getVehiclesHandler)
		api.GET("/vehicles/:id", getVehicleHandler)
		
		// Driver endpoints
		api.POST("/drivers", middleware.AuthRequired(), createDriverHandler)
		api.GET("/drivers", getDriversHandler)
		api.GET("/drivers/:id", getDriverHandler)
		
		// Trip endpoints
		api.POST("/trips", middleware.AuthRequired(), createTripHandler)
		api.GET("/trips", getTripsHandler)
		api.GET("/trips/:id", getTripHandler)
		
		// Analytics endpoints
		api.GET("/dashboard/stats", getDashboardStatsHandler)
		api.GET("/dashboard/vehicle-utilization", getVehicleUtilizationHandler)
		
		// Fleet management endpoints
		api.POST("/fleet/register", middleware.AuthRequired(), registerFleetOwnerHandler)
		api.GET("/fleet/profile", middleware.AuthRequired(), getFleetProfileHandler)
		api.POST("/fleet/vehicles", middleware.AuthRequired(), registerFleetVehicleHandler)
		api.GET("/fleet/vehicles", middleware.AuthRequired(), getFleetVehiclesHandler)
		
		// File upload endpoints
		api.POST("/upload/document", middleware.AuthRequired(), uploadDocumentHandler)
		api.POST("/vehicles/:id/attachments", middleware.AuthRequired(), uploadVehicleAttachmentHandler)
		api.GET("/vehicles/:id/attachments", middleware.AuthRequired(), getVehicleAttachmentsHandler)
		api.DELETE("/vehicles/:id/attachments/:attachmentId", middleware.AuthRequired(), deleteVehicleAttachmentHandler)
		api.GET("/files/:filename", serveFileHandler)
		
		// Admin endpoints
		api.GET("/admin/dashboard", middleware.AuthRequired(), middleware.AdminRequired(), getAdminDashboardHandler)
		api.GET("/admin/verification-dashboard", middleware.AuthRequired(), middleware.AdminRequired(), getAdminVerificationDashboardHandler)
		api.GET("/admin/vehicles/pending", middleware.AuthRequired(), middleware.AdminRequired(), getPendingVehiclesHandler)
		api.GET("/admin/vehicles/status/:status", middleware.AuthRequired(), middleware.AdminRequired(), getVehiclesByStatusHandler)
		api.GET("/admin/vehicles", middleware.AuthRequired(), middleware.AdminRequired(), getAllVehiclesAdminHandler)
		api.GET("/admin/vehicles/:id", middleware.AuthRequired(), middleware.AdminRequired(), getVehicleDetailsAdminHandler)
		api.PUT("/admin/vehicles/:id/verify", middleware.AuthRequired(), middleware.AdminRequired(), verifyVehicleHandler)
		api.PUT("/admin/vehicles/:id/correction", middleware.AuthRequired(), middleware.AdminRequired(), requestCorrectionHandler)
		api.POST("/admin/vehicles/:id/cross-check", middleware.AuthRequired(), middleware.AdminRequired(), performCrossCheckHandler)
		api.POST("/admin/vehicles/:id/schedule-inspection", middleware.AuthRequired(), middleware.AdminRequired(), scheduleInspectionHandler)
		api.GET("/admin/vehicles/:id/history", middleware.AuthRequired(), middleware.AdminRequired(), getVehicleVerificationHistoryHandler)
		api.GET("/admin/documents", middleware.AuthRequired(), middleware.AdminRequired(), getUploadedDocumentsHandler)
		api.PUT("/admin/documents/:id/verify", middleware.AuthRequired(), middleware.AdminRequired(), verifyDocumentHandler)
		
		// Enhanced dashboard endpoints
		api.GET("/notifications", middleware.AuthRequired(), getNotificationsHandler)
		api.PUT("/notifications/:id/read", middleware.AuthRequired(), markNotificationReadHandler)
		api.GET("/fleet/tracking", middleware.AuthRequired(), getVehicleTrackingHandler)
		api.GET("/fleet/analytics", middleware.AuthRequired(), getRevenueAnalyticsHandler)
		
		// GPS Registration endpoints
		api.POST("/gps-registration", createGPSRegistrationHandler)
		api.GET("/gps-registration", middleware.AuthRequired(), middleware.AdminRequired(), getAllGPSRegistrationsHandler)
		api.GET("/gps-registration/pending", middleware.AuthRequired(), middleware.AdminRequired(), getPendingGPSRegistrationsHandler)
		api.PUT("/gps-registration/:id/approve", middleware.AuthRequired(), middleware.AdminRequired(), approveGPSRegistrationHandler)
		api.GET("/gps-registration/:id", middleware.AuthRequired(), getGPSRegistrationByIDHandler)
		
		// OCR endpoints
		api.POST("/ocr/stnk", middleware.AuthRequired(), extractSTNKHandler)
		api.POST("/ocr/ktp", middleware.AuthRequired(), extractKTPHandler)
		api.POST("/ocr/face-match", middleware.AuthRequired(), faceMatchHandler)
		api.POST("/ocr/validate-quality", middleware.AuthRequired(), validateQualityHandler)
		
		// Document upload endpoints
		api.POST("/documents/upload", middleware.AuthRequired(), uploadDocumentDirectHandler)
		
		// Driver mobile app endpoints
		api.GET("/driver/profile", middleware.AuthRequired(), getDriverProfileHandler)
		api.GET("/driver/trips", middleware.AuthRequired(), getDriverTripsHandler)
		api.PUT("/driver/trips/:id/status", middleware.AuthRequired(), updateTripStatusHandler)
		api.POST("/driver/trips/:id/tracking", middleware.AuthRequired(), recordTripTrackingHandler)

	}

	// Get port from environment or default to 8080
	port := os.Getenv("SERVER_PORT")
	if port == "" {
		port = "8080"
	}

	log.Printf("Server starting on port %s", port)
	if err := r.Run(":" + port); err != nil {
		log.Fatal("Failed to start server:", err)
	}
}

func registerHandler(c *gin.Context) {
	
	var req models.RegisterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request format"})
		return
	}
	
	conn, err := db.Connect()
	if err != nil {
		log.Printf("Database connection error: %v", middleware.SanitizeForLog(err.Error()))
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Database error"})
		return
	}
	// Let connection pool manage connections
	
	user, err := auth.CreateUser(conn, req)
	if err != nil {
		log.Printf("Create user error: %v", middleware.SanitizeForLog(err.Error()))
		if strings.Contains(err.Error(), "already exists") {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Username atau email sudah terdaftar"})
		} else {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Gagal membuat akun"})
		}
		return
	}
	
	token, err := auth.GenerateToken(user.ID, user.Username, user.Role)
	if err != nil {
		log.Printf("Token generation error: %v", middleware.SanitizeForLog(err.Error()))
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to generate token"})
		return
	}
	
	c.JSON(http.StatusCreated, models.LoginResponse{
		Token: token,
		User: models.UserResponse{
			ID:        user.ID,
			Username:  user.Username,
			Email:     user.Email,
			FullName:  user.FullName,
			Role:      user.Role,
			CreatedAt: user.CreatedAt,
			UpdatedAt: user.UpdatedAt,
		},
	})
}

func loginHandler(c *gin.Context) {
	
	var req models.LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		log.Printf("Login request binding error: %v", middleware.SanitizeForLog(err.Error()))
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request format"})
		return
	}
	
	log.Printf("Login attempt for user: %s", middleware.SanitizeForLog(req.Email))
	
	conn, err := db.Connect()
	if err != nil {
		log.Printf("Database connection error: %v", middleware.SanitizeForLog(err.Error()))
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Database error"})
		return
	}
	// Don't close connection - let pool manage it
	
	user, err := auth.LoginUser(conn, req)
	if err != nil {
		log.Printf("Login error for user: %s - %v", middleware.SanitizeForLog(req.Email), middleware.SanitizeForLog(err.Error()))
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Email/username atau kata sandi salah"})
		return
	}
	
	token, err := auth.GenerateToken(user.ID, user.Username, user.Role)
	if err != nil {
		log.Printf("Token generation error: %v", middleware.SanitizeForLog(err.Error()))
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to generate token"})
		return
	}
	
	log.Printf("Login successful for user ID: %d", user.ID)
	
	c.JSON(http.StatusOK, models.LoginResponse{
		Token: token,
		User: models.UserResponse{
			ID:        user.ID,
			Username:  user.Username,
			Email:     user.Email,
			FullName:  user.FullName,
			Role:      user.Role,
			CreatedAt: user.CreatedAt,
			UpdatedAt: user.UpdatedAt,
		},
	})
}

func createVehicleHandler(c *gin.Context) {
	var req models.VehicleRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request format"})
		return
	}
	
	conn, err := db.Connect()
	if err != nil {
		log.Printf("Database connection error: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Database error"})
		return
	}
	// Let connection pool manage connections
	
	// Get user ID from context (set by auth middleware)
	userID, exists := c.Get("user_id")
	if !exists {
		userID = 1 // Fallback for development
	}
	
	// Safe type assertion
	var userIDInt int
	if id, ok := userID.(int); ok {
		userIDInt = id
	} else {
		log.Printf("Invalid user_id type in context: %T", userID)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Authentication error"})
		return
	}
	
	vehicle, err := services.CreateVehicle(conn, req, userIDInt)
	if err != nil {
		log.Printf("Create vehicle error: %v", err)
		c.JSON(http.StatusBadRequest, gin.H{"error": "Failed to create vehicle"})
		return
	}
	
	c.JSON(http.StatusCreated, gin.H{"vehicle": vehicle})
}

func getVehiclesHandler(c *gin.Context) {
	conn, err := db.Connect()
	if err != nil {
		log.Printf("Database connection error: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Database error"})
		return
	}
	// Let connection pool manage connections
	
	// Check if requesting approved vehicles only
	if c.Query("status") == "approved" {
		vehicles, err := services.GetApprovedVehicles(conn)
		if err != nil {
			log.Printf("Get approved vehicles error: %v", err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get approved vehicles"})
			return
		}
		c.JSON(http.StatusOK, gin.H{"vehicles": vehicles})
		return
	}
	
	vehicles, err := services.GetVehicles(conn)
	if err != nil {
		log.Printf("Get vehicles error: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get vehicles"})
		return
	}
	
	c.JSON(http.StatusOK, gin.H{"vehicles": vehicles})
}

func getVehicleHandler(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.Atoi(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid vehicle ID"})
		return
	}
	
	conn, err := db.Connect()
	if err != nil {
		log.Printf("Database connection error: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Database error"})
		return
	}
	// Let connection pool manage connections
	
	vehicle, err := services.GetVehicleByID(conn, id)
	if err != nil {
		log.Printf("Get vehicle error: %v", err)
		c.JSON(http.StatusNotFound, gin.H{"error": "Vehicle not found"})
		return
	}
	
	c.JSON(http.StatusOK, gin.H{"vehicle": vehicle})
}

func getApprovedVehiclesHandler(c *gin.Context) {
	conn, err := db.Connect()
	if err != nil {
		log.Printf("Database connection error: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Database error"})
		return
	}
	
	vehicles, err := services.GetApprovedVehicles(conn)
	if err != nil {
		log.Printf("Get approved vehicles error: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get approved vehicles"})
		return
	}
	
	c.JSON(http.StatusOK, gin.H{"vehicles": vehicles})
}

// Driver handlers
func createDriverHandler(c *gin.Context) {
	var req models.DriverRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request format"})
		return
	}
	
	// TODO: Implement CreateDriver service
	c.JSON(http.StatusNotImplemented, gin.H{"error": "Driver creation not implemented yet"})
}

func getDriversHandler(c *gin.Context) {
	// TODO: Implement GetDrivers service
	c.JSON(http.StatusNotImplemented, gin.H{"error": "Get drivers not implemented yet"})
}

func getDriverHandler(c *gin.Context) {
	// TODO: Implement GetDriverByID service
	c.JSON(http.StatusNotImplemented, gin.H{"error": "Get driver by ID not implemented yet"})
}

// Trip handlers
func createTripHandler(c *gin.Context) {
	var req models.TripRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request format"})
		return
	}
	
	conn, err := db.Connect()
	if err != nil {
		log.Printf("Database connection error: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Database error"})
		return
	}
	// Let connection pool manage connections
	
	trip, err := services.CreateTrip(conn, req)
	if err != nil {
		log.Printf("Create trip error: %v", err)
		c.JSON(http.StatusBadRequest, gin.H{"error": "Failed to create trip"})
		return
	}
	
	c.JSON(http.StatusCreated, gin.H{"trip": trip})
}

func getTripsHandler(c *gin.Context) {
	conn, err := db.Connect()
	if err != nil {
		log.Printf("Database connection error: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Database error"})
		return
	}
	// Let connection pool manage connections
	
	trips, err := services.GetTrips(conn)
	if err != nil {
		log.Printf("Get trips error: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get trips"})
		return
	}
	
	c.JSON(http.StatusOK, gin.H{"trips": trips})
}

func getTripHandler(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.Atoi(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid trip ID"})
		return
	}
	
	conn, err := db.Connect()
	if err != nil {
		log.Printf("Database connection error: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Database error"})
		return
	}
	// Let connection pool manage connections
	
	trip, err := services.GetTripByID(conn, id)
	if err != nil {
		log.Printf("Get trip error: %v", err)
		c.JSON(http.StatusNotFound, gin.H{"error": "Trip not found"})
		return
	}
	
	c.JSON(http.StatusOK, gin.H{"trip": trip})
}

// Analytics handlers
func getDashboardStatsHandler(c *gin.Context) {
	conn, err := db.Connect()
	if err != nil {
		log.Printf("Database connection error: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Database error"})
		return
	}
	// Let connection pool manage connections
	
	stats, err := services.GetDashboardStats(conn)
	if err != nil {
		log.Printf("Get dashboard stats error: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get dashboard stats"})
		return
	}
	
	c.JSON(http.StatusOK, gin.H{"stats": stats})
}

func getVehicleUtilizationHandler(c *gin.Context) {
	conn, err := db.Connect()
	if err != nil {
		log.Printf("Database connection error: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Database error"})
		return
	}
	// Let connection pool manage connections
	
	utilization, err := services.GetVehicleUtilization(conn)
	if err != nil {
		log.Printf("Get vehicle utilization error: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get vehicle utilization"})
		return
	}
	
	c.JSON(http.StatusOK, gin.H{"utilization": utilization})
}

// File upload handlers
func uploadVehicleAttachmentHandler(c *gin.Context) {
	vehicleIDStr := c.Param("id")
	vehicleID, err := strconv.Atoi(vehicleIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid vehicle ID"})
		return
	}

	// Check if it's multipart form or JSON
	contentType := c.GetHeader("Content-Type")
	if strings.Contains(contentType, "application/json") {
		// Handle JSON upload (for simulation)
		var req struct {
			AttachmentType string `json:"attachment_type"`
			FileName       string `json:"file_name"`
			FileSize       int    `json:"file_size"`
			MimeType       string `json:"mime_type"`
			Data           string `json:"data"` // Base64 image data
		}

		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request format"})
			return
		}

		conn, err := db.Connect()
		if err != nil {
			log.Printf("Database connection error: %v", err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Database error"})
			return
		}

		// Save base64 image data to file if provided
		filePath := fmt.Sprintf("./uploads/%s", req.FileName)
		if req.Data != "" {
			// Create uploads directory if not exists
			os.MkdirAll("./uploads", 0755)
			
			// Save base64 data directly to file for serving
			file, err := os.Create(filePath)
			if err == nil {
				file.WriteString(req.Data) // Save full base64 data
				file.Close()
			}
		}

		// Create attachment record
		query := `INSERT INTO vehicle_attachments (vehicle_id, attachment_type, file_name, file_path, file_size, mime_type)
				  VALUES ($1, $2, $3, $4, $5, $6) RETURNING id, uploaded_at`

		var attachmentID int
		var uploadedAt time.Time
		err = conn.QueryRow(query, vehicleID, req.AttachmentType, req.FileName, filePath, req.FileSize, req.MimeType).
			Scan(&attachmentID, &uploadedAt)

		if err != nil {
			log.Printf("Insert attachment error: %v", err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to save attachment"})
			return
		}

		c.JSON(http.StatusCreated, gin.H{
			"attachment": gin.H{
				"id":              attachmentID,
				"vehicle_id":      vehicleID,
				"attachment_type": req.AttachmentType,
				"file_name":       req.FileName,
				"file_path":       filePath,
				"file_size":       req.FileSize,
				"mime_type":       req.MimeType,
				"uploaded_at":     uploadedAt,
			},
		})
		return
	}

	// Original multipart form handling
	attachmentType := c.PostForm("attachment_type")
	if attachmentType == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Attachment type is required"})
		return
	}

	file, header, err := c.Request.FormFile("file")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "No file uploaded"})
		return
	}
	defer file.Close()

	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Authentication required"})
		return
	}

	userIDInt, ok := userID.(int)
	if !ok {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Invalid user ID"})
		return
	}

	conn, err := db.Connect()
	if err != nil {
		log.Printf("Database connection error: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Database error"})
		return
	}

	// Verify vehicle ownership
	fleetOwner, err := services.GetFleetOwnerByUserID(conn, userIDInt)
	if err != nil {
		c.JSON(http.StatusForbidden, gin.H{"error": "Access denied"})
		return
	}

	// Check if vehicle belongs to fleet owner
	var vehicleFleetOwnerID int
	err = conn.QueryRow("SELECT fleet_owner_id FROM vehicles WHERE id = $1", vehicleID).Scan(&vehicleFleetOwnerID)
	if err != nil || vehicleFleetOwnerID != fleetOwner.ID {
		c.JSON(http.StatusForbidden, gin.H{"error": "Vehicle not found or access denied"})
		return
	}

	attachment, err := services.UploadVehicleAttachment(conn, vehicleID, attachmentType, file, header)
	if err != nil {
		log.Printf("Upload attachment error: %v", err)
		c.JSON(http.StatusBadRequest, gin.H{"error": "Failed to upload attachment"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{"attachment": attachment})
}

func getVehicleAttachmentsHandler(c *gin.Context) {
	vehicleIDStr := c.Param("id")
	vehicleID, err := strconv.Atoi(vehicleIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid vehicle ID"})
		return
	}

	conn, err := db.Connect()
	if err != nil {
		log.Printf("Database connection error: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Database error"})
		return
	}

	attachments, err := services.GetVehicleAttachments(conn, vehicleID)
	if err != nil {
		log.Printf("Get attachments error: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get attachments"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"attachments": attachments})
}

func deleteVehicleAttachmentHandler(c *gin.Context) {
	vehicleIDStr := c.Param("id")
	vehicleID, err := strconv.Atoi(vehicleIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid vehicle ID"})
		return
	}

	attachmentIDStr := c.Param("attachmentId")
	attachmentID, err := strconv.Atoi(attachmentIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid attachment ID"})
		return
	}

	conn, err := db.Connect()
	if err != nil {
		log.Printf("Database connection error: %s", strings.ReplaceAll(err.Error(), "\n", " "))
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Database error"})
		return
	}

	err = services.DeleteVehicleAttachment(conn, attachmentID, vehicleID)
	if err != nil {
		log.Printf("Delete attachment error: %s", middleware.SanitizeForLog(err.Error()))
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Attachment deleted successfully"})
}

func serveFileHandler(c *gin.Context) {
	filename := c.Param("filename")
	
	// Security check - prevent directory traversal
	if strings.Contains(filename, "..") || strings.Contains(filename, "/") || strings.Contains(filename, "\\") {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid filename"})
		return
	}
	
	// Use filepath.Base to get only filename without path
	safeFilename := filepath.Base(filename)
	if safeFilename != filename {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid filename"})
		return
	}
	
	// Construct safe file path
	uploadsDir := "./uploads"
	filePath := filepath.Join(uploadsDir, safeFilename)
	
	// Verify the resolved path is within uploads directory
	absUploadsDir, err := filepath.Abs(uploadsDir)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Server error"})
		return
	}
	
	absFilePath, err := filepath.Abs(filePath)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Server error"})
		return
	}
	
	if !strings.HasPrefix(absFilePath, absUploadsDir) {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid file path"})
		return
	}

	// Check if file exists
	if _, err := os.Stat(filePath); os.IsNotExist(err) {
		c.JSON(http.StatusNotFound, gin.H{"error": "File not found"})
		return
	}

	// Read file content
	content, err := os.ReadFile(filePath)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to read file"})
		return
	}

	// Check if it's base64 data
	contentStr := string(content)
	if strings.HasPrefix(contentStr, "data:image/") {
		// Return base64 data as JSON for frontend to display
		c.JSON(http.StatusOK, gin.H{
			"type": "base64",
			"data": contentStr,
		})
		return
	}

	// Serve regular file
	c.File(filePath)
}

// Admin handlers
func getAdminDashboardHandler(c *gin.Context) {
	conn, err := db.Connect()
	if err != nil {
		log.Printf("Database connection error: %s", strings.ReplaceAll(err.Error(), "\n", " "))
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Database error"})
		return
	}

	stats, err := services.GetAdminDashboardStats(conn)
	if err != nil {
		log.Printf("Get admin stats error: %s", strings.ReplaceAll(err.Error(), "\n", " "))
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get dashboard stats"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"stats": stats})
}

func getPendingVehiclesHandler(c *gin.Context) {
	conn, err := db.Connect()
	if err != nil {
		log.Printf("Database connection error: %s", strings.ReplaceAll(err.Error(), "\n", " "))
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Database error"})
		return
	}

	// Simple implementation to get pending vehicles
	query := `SELECT v.id, v.registration_number, v.vehicle_type, v.brand, v.model, v.year,
					 v.chassis_number, v.engine_number, v.color, v.capacity_weight,
					 v.ownership_status, v.verification_status, v.created_at, v.created_by,
					 u.username, u.email, u.full_name
			  FROM vehicles v
			  JOIN users u ON v.created_by = u.id
			  WHERE v.verification_status = 'pending' OR v.verification_status = 'submitted'
			  ORDER BY v.created_at DESC`

	rows, err := conn.Query(query)
	if err != nil {
		log.Printf("Query pending vehicles error: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get pending vehicles"})
		return
	}
	defer rows.Close()

	var vehicles []map[string]interface{}
	for rows.Next() {
		var vehicle map[string]interface{} = make(map[string]interface{})
		var id, createdBy, year int
		var registrationNumber, vehicleType, brand, model, chassisNumber, engineNumber, color, ownershipStatus, verificationStatus, username, email, fullName string
		var capacityWeight float64
		var createdAt time.Time

		err := rows.Scan(&id, &registrationNumber, &vehicleType, &brand, &model, &year,
			&chassisNumber, &engineNumber, &color, &capacityWeight,
			&ownershipStatus, &verificationStatus, &createdAt, &createdBy,
			&username, &email, &fullName)
		if err != nil {
			continue
		}

		vehicle["id"] = id
		vehicle["registration_number"] = registrationNumber
		vehicle["vehicle_type"] = vehicleType
		vehicle["brand"] = brand
		vehicle["model"] = model
		vehicle["year"] = year
		vehicle["chassis_number"] = chassisNumber
		vehicle["engine_number"] = engineNumber
		vehicle["color"] = color
		vehicle["capacity_weight"] = capacityWeight
		vehicle["ownership_status"] = ownershipStatus
		vehicle["verification_status"] = verificationStatus
		vehicle["created_at"] = createdAt
		vehicle["created_by"] = createdBy
		vehicle["owner_name"] = fullName
		vehicle["owner_email"] = email
		vehicle["username"] = username
		vehicle["days_waiting"] = int(time.Since(createdAt).Hours() / 24)

		vehicles = append(vehicles, vehicle)
	}

	c.JSON(http.StatusOK, gin.H{"vehicles": vehicles})
}

func getAllVehiclesAdminHandler(c *gin.Context) {
	conn, err := db.Connect()
	if err != nil {
		log.Printf("Database connection error: %s", strings.ReplaceAll(err.Error(), "\n", " "))
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Database error"})
		return
	}

	vehicles, err := services.GetAllVehiclesForAdmin(conn)
	if err != nil {
		log.Printf("Get all vehicles error: %s", strings.ReplaceAll(err.Error(), "\n", " "))
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get vehicles"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"vehicles": vehicles})
}

func getVehicleDetailsAdminHandler(c *gin.Context) {
	vehicleIDStr := c.Param("id")
	vehicleID, err := strconv.Atoi(vehicleIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid vehicle ID"})
		return
	}

	log.Printf("DEBUG: Getting vehicle details for ID: %d", vehicleID)

	conn, err := db.Connect()
	if err != nil {
		log.Printf("Database connection error: %s", strings.ReplaceAll(err.Error(), "\n", " "))
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Database error"})
		return
	}

	vehicle, err := services.GetVehicleDetailsForAdmin(conn, vehicleID)
	if err != nil {
		if strings.Contains(err.Error(), "not found") {
			c.JSON(http.StatusNotFound, gin.H{"error": "Vehicle not found"})
		} else {
			log.Printf("Get vehicle details error: %s", strings.ReplaceAll(err.Error(), "\n", " "))
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get vehicle details"})
		}
		return
	}

	c.JSON(http.StatusOK, gin.H{"vehicle": vehicle})
}

func verifyVehicleHandler(c *gin.Context) {
	vehicleIDStr := c.Param("id")
	vehicleID, err := strconv.Atoi(vehicleIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid vehicle ID"})
		return
	}

	var req struct {
		Status string `json:"status" binding:"required"`
		Notes  string `json:"notes"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request format"})
		return
	}

	conn, err := db.Connect()
	if err != nil {
		log.Printf("Database connection error: %s", strings.ReplaceAll(err.Error(), "\n", " "))
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Database error"})
		return
	}

	// Get admin user ID from context
	adminID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Admin authentication required"})
		return
	}

	adminIDInt, ok := adminID.(int)
	if !ok {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Invalid admin ID"})
		return
	}

	err = services.UpdateVehicleVerificationStatus(conn, vehicleID, req.Status, req.Notes, adminIDInt)
	if err != nil {
		log.Printf("Update verification status error: %s", strings.ReplaceAll(err.Error(), "\n", " "))
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Send notification after verification
	go func() {
		notificationService := services.NewNotificationService(conn)
		templateKey := "approved"
		extraVars := map[string]interface{}{}
		
		if req.Status == "rejected" {
			templateKey = "rejected"
			extraVars["reason"] = req.Notes
		}
		
		err := notificationService.SendVehicleNotification(vehicleID, templateKey, extraVars)
		if err != nil {
			log.Printf("Failed to send verification notification: %v", err)
		}
	}()

	c.JSON(http.StatusOK, gin.H{"message": "Vehicle verification status updated successfully"})
}

func getVehicleVerificationHistoryHandler(c *gin.Context) {
	vehicleIDStr := c.Param("id")
	vehicleID, err := strconv.Atoi(vehicleIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid vehicle ID"})
		return
	}

	conn, err := db.Connect()
	if err != nil {
		log.Printf("Database connection error: %s", strings.ReplaceAll(err.Error(), "\n", " "))
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Database error"})
		return
	}

	history, err := services.GetVerificationHistory(conn, vehicleID)
	if err != nil {
		log.Printf("Get verification history error: %s", strings.ReplaceAll(err.Error(), "\n", " "))
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get verification history"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"history": history})
}

// Enhanced dashboard handlers
func getNotificationsHandler(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Authentication required"})
		return
	}

	userIDInt, ok := userID.(int)
	if !ok {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Invalid user ID"})
		return
	}

	limit := 20 // Default limit
	if limitStr := c.Query("limit"); limitStr != "" {
		if l, err := strconv.Atoi(limitStr); err == nil && l > 0 && l <= 100 {
			limit = l
		}
	}

	conn, err := db.Connect()
	if err != nil {
		log.Printf("Database connection error: %s", strings.ReplaceAll(err.Error(), "\n", " "))
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Database error"})
		return
	}

	notifications, err := services.GetNotifications(conn, userIDInt, limit)
	if err != nil {
		log.Printf("Get notifications error: %s", strings.ReplaceAll(err.Error(), "\n", " "))
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get notifications"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"notifications": notifications})
}

func markNotificationReadHandler(c *gin.Context) {
	notificationIDStr := c.Param("id")
	notificationID, err := strconv.Atoi(notificationIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid notification ID"})
		return
	}

	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Authentication required"})
		return
	}

	userIDInt, ok := userID.(int)
	if !ok {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Invalid user ID"})
		return
	}

	conn, err := db.Connect()
	if err != nil {
		log.Printf("Database connection error: %s", strings.ReplaceAll(err.Error(), "\n", " "))
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Database error"})
		return
	}

	err = services.MarkNotificationAsRead(conn, notificationID, userIDInt)
	if err != nil {
		log.Printf("Mark notification read error: %s", strings.ReplaceAll(err.Error(), "\n", " "))
		c.JSON(http.StatusBadRequest, gin.H{"error": "Failed to mark notification as read"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Notification marked as read"})
}

func getVehicleTrackingHandler(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Authentication required"})
		return
	}

	userIDInt, ok := userID.(int)
	if !ok {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Invalid user ID"})
		return
	}

	conn, err := db.Connect()
	if err != nil {
		log.Printf("Database connection error: %s", strings.ReplaceAll(err.Error(), "\n", " "))
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Database error"})
		return
	}

	// Get fleet owner ID
	fleetOwner, err := services.GetFleetOwnerByUserID(conn, userIDInt)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Fleet owner profile not found"})
		return
	}

	tracking, err := services.GetVehicleTracking(conn, fleetOwner.ID)
	if err != nil {
		log.Printf("Get vehicle tracking error: %s", strings.ReplaceAll(err.Error(), "\n", " "))
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get vehicle tracking"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"tracking": tracking})
}

func getRevenueAnalyticsHandler(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Authentication required"})
		return
	}

	userIDInt, ok := userID.(int)
	if !ok {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Invalid user ID"})
		return
	}

	days := 30 // Default 30 days
	if daysStr := c.Query("days"); daysStr != "" {
		if d, err := strconv.Atoi(daysStr); err == nil && d > 0 && d <= 365 {
			days = d
		}
	}

	conn, err := db.Connect()
	if err != nil {
		log.Printf("Database connection error: %s", strings.ReplaceAll(err.Error(), "\n", " "))
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Database error"})
		return
	}

	// Get fleet owner ID
	fleetOwner, err := services.GetFleetOwnerByUserID(conn, userIDInt)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Fleet owner profile not found"})
		return
	}

	analytics, err := services.GetRevenueAnalytics(conn, fleetOwner.ID, days)
	if err != nil {
		log.Printf("Get revenue analytics error: %s", strings.ReplaceAll(err.Error(), "\n", " "))
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get revenue analytics"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"analytics": analytics})
}

// Driver mobile app handlers
func getDriverProfileHandler(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Authentication required"})
		return
	}

	userIDInt, ok := userID.(int)
	if !ok {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Invalid user ID"})
		return
	}

	conn, err := db.Connect()
	if err != nil {
		log.Printf("Database connection error: %s", strings.ReplaceAll(err.Error(), "\n", " "))
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Database error"})
		return
	}

	driver, err := services.GetDriverByUserID(conn, userIDInt)
	if err != nil {
		if strings.Contains(err.Error(), "not found") {
			c.JSON(http.StatusNotFound, gin.H{"error": "Driver profile not found"})
		} else {
			log.Printf("Get driver profile error: %s", strings.ReplaceAll(err.Error(), "\n", " "))
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get driver profile"})
		}
		return
	}

	c.JSON(http.StatusOK, gin.H{"driver": driver})
}

func getDriverTripsHandler(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Authentication required"})
		return
	}

	userIDInt, ok := userID.(int)
	if !ok {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Invalid user ID"})
		return
	}

	conn, err := db.Connect()
	if err != nil {
		log.Printf("Database connection error: %s", strings.ReplaceAll(err.Error(), "\n", " "))
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Database error"})
		return
	}

	// Get driver ID
	driver, err := services.GetDriverByUserID(conn, userIDInt)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Driver profile not found"})
		return
	}

	status := c.Query("status")
	driverID, ok := driver["id"].(int)
	if !ok {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Invalid driver ID type"})
		return
	}
	trips, err := services.GetDriverTrips(conn, driverID, status)
	if err != nil {
		log.Printf("Get driver trips error: %s", strings.ReplaceAll(err.Error(), "\n", " "))
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get trips"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"trips": trips})
}

func updateTripStatusHandler(c *gin.Context) {
	tripIDStr := c.Param("id")
	tripID, err := strconv.Atoi(tripIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid trip ID"})
		return
	}

	var req struct {
		Status string `json:"status" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request format"})
		return
	}

	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Authentication required"})
		return
	}

	userIDInt, ok := userID.(int)
	if !ok {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Invalid user ID"})
		return
	}

	conn, err := db.Connect()
	if err != nil {
		log.Printf("Database connection error: %s", strings.ReplaceAll(err.Error(), "\n", " "))
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Database error"})
		return
	}

	// Get driver ID
	driver, err := services.GetDriverByUserID(conn, userIDInt)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Driver profile not found"})
		return
	}

	driverID, ok := driver["id"].(int)
	if !ok {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Invalid driver ID type"})
		return
	}
	err = services.UpdateTripStatus(conn, tripID, driverID, req.Status)
	if err != nil {
		log.Printf("Update trip status error: %s", strings.ReplaceAll(err.Error(), "\n", " "))
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Trip status updated successfully"})
}

func recordTripTrackingHandler(c *gin.Context) {
	tripIDStr := c.Param("id")
	tripID, err := strconv.Atoi(tripIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid trip ID"})
		return
	}

	var req struct {
		Latitude  float64 `json:"latitude" binding:"required"`
		Longitude float64 `json:"longitude" binding:"required"`
		Speed     float64 `json:"speed"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request format"})
		return
	}

	conn, err := db.Connect()
	if err != nil {
		log.Printf("Database connection error: %s", strings.ReplaceAll(err.Error(), "\n", " "))
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Database error"})
		return
	}

	err = services.RecordTripTracking(conn, tripID, req.Latitude, req.Longitude, req.Speed)
	if err != nil {
		log.Printf("Record trip tracking error: %s", strings.ReplaceAll(err.Error(), "\n", " "))
		c.JSON(http.StatusBadRequest, gin.H{"error": "Failed to record tracking"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Tracking recorded successfully"})
}

// Fleet handlers
func registerFleetOwnerHandler(c *gin.Context) {
	var req models.FleetOwnerRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		log.Printf("Fleet registration binding error: %v", err)
		c.JSON(http.StatusBadRequest, gin.H{"error": fmt.Sprintf("Invalid request format: %v", err)})
		return
	}
	
	// Log the received request for debugging
	log.Printf("Fleet registration request: CompanyName=%s, Address=%s, Phone=%s, Email=%s", 
		req.CompanyName, req.Address, req.PhoneNumber, req.Email)
	
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Authentication required"})
		return
	}
	
	userIDInt, ok := userID.(int)
	if !ok {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Invalid user ID"})
		return
	}
	
	conn, err := db.Connect()
	if err != nil {
		log.Printf("Database connection error: %s", strings.ReplaceAll(err.Error(), "\n", " "))
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Database error"})
		return
	}
	
	fleetOwner, err := services.RegisterFleetOwner(conn, req, userIDInt)
	if err != nil {
		log.Printf("Register fleet owner error: %s", strings.ReplaceAll(err.Error(), "\n", " "))
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	
	c.JSON(http.StatusCreated, gin.H{"fleet_owner": fleetOwner})
}

func getFleetProfileHandler(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Authentication required"})
		return
	}
	
	userIDInt, ok := userID.(int)
	if !ok {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Invalid user ID"})
		return
	}
	
	conn, err := db.Connect()
	if err != nil {
		log.Printf("Database connection error: %s", strings.ReplaceAll(err.Error(), "\n", " "))
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Database error"})
		return
	}
	
	fleetOwner, err := services.GetFleetOwnerByUserID(conn, userIDInt)
	if err != nil {
		if strings.Contains(err.Error(), "not found") {
			c.JSON(http.StatusNotFound, gin.H{"error": "Fleet owner profile not found"})
		} else {
			log.Printf("Get fleet profile error: %s", strings.ReplaceAll(err.Error(), "\n", " "))
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get profile"})
		}
		return
	}
	
	c.JSON(http.StatusOK, gin.H{"fleet_owner": fleetOwner})
}

func registerFleetVehicleHandler(c *gin.Context) {
	// Accept any JSON structure for vehicle registration
	var req map[string]interface{}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request format"})
		return
	}
	
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Authentication required"})
		return
	}
	
	userIDInt, ok := userID.(int)
	if !ok {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Invalid user ID"})
		return
	}
	
	conn, err := db.Connect()
	if err != nil {
		log.Printf("Database connection error: %s", strings.ReplaceAll(err.Error(), "\n", " "))
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Database error"})
		return
	}
	
	// Simple vehicle registration - insert directly to vehicles table
	query := `INSERT INTO vehicles (
		registration_number, vehicle_type, brand, model, year, 
		chassis_number, engine_number, color, capacity_weight,
		ownership_status, created_by, verification_status
	) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, 'pending') 
	RETURNING id, created_at`
	
	var vehicleID int
	var createdAt time.Time
	
	// Extract data from request with defaults
	registrationNumber := getStringValue(req, "registration_number")
	vehicleType := getStringValue(req, "vehicle_type")
	brand := getStringValue(req, "brand")
	model := getStringValue(req, "model")
	year := getIntValue(req, "year", 2020)
	chassisNumber := getStringValue(req, "chassis_number")
	engineNumber := getStringValue(req, "engine_number")
	color := getStringValue(req, "color")
	capacityWeight := getFloatValue(req, "capacity_weight", 0.0)
	ownershipStatus := getStringValue(req, "ownership_status")
	
	err = conn.QueryRow(query, 
		registrationNumber, vehicleType, brand, model, year,
		chassisNumber, engineNumber, color, capacityWeight,
		ownershipStatus, userIDInt,
	).Scan(&vehicleID, &createdAt)
	
	if err != nil {
		log.Printf("Insert vehicle error: %v", err)
		if strings.Contains(err.Error(), "duplicate key value violates unique constraint") {
			if strings.Contains(err.Error(), "registration_number") {
				c.JSON(http.StatusBadRequest, gin.H{"error": "Nomor plat kendaraan sudah terdaftar. Silakan gunakan nomor plat yang berbeda."})
			} else if strings.Contains(err.Error(), "chassis_number") {
				c.JSON(http.StatusBadRequest, gin.H{"error": "Nomor rangka kendaraan sudah terdaftar. Silakan periksa kembali nomor rangka."})
			} else {
				c.JSON(http.StatusBadRequest, gin.H{"error": "Data kendaraan sudah terdaftar dalam sistem."})
			}
		} else {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal mendaftarkan kendaraan. Silakan coba lagi."})
		}
		return
	}
	
	// Return success response
	vehicle := map[string]interface{}{
		"id": vehicleID,
		"registration_number": registrationNumber,
		"vehicle_type": vehicleType,
		"brand": brand,
		"model": model,
		"year": year,
		"verification_status": "pending",
		"created_at": createdAt,
	}
	
	c.JSON(http.StatusCreated, gin.H{"vehicle": vehicle})
}

// Helper functions for extracting values from map
func getStringValue(m map[string]interface{}, key string) string {
	if val, ok := m[key]; ok {
		if str, ok := val.(string); ok {
			return str
		}
	}
	return ""
}

func getIntValue(m map[string]interface{}, key string, defaultVal int) int {
	if val, ok := m[key]; ok {
		if num, ok := val.(float64); ok {
			return int(num)
		}
		if num, ok := val.(int); ok {
			return num
		}
	}
	return defaultVal
}

func getFloatValue(m map[string]interface{}, key string, defaultVal float64) float64 {
	if val, ok := m[key]; ok {
		if num, ok := val.(float64); ok {
			return num
		}
		if num, ok := val.(int); ok {
			return float64(num)
		}
	}
	return defaultVal
}

func getFleetVehiclesHandler(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Authentication required"})
		return
	}
	
	userIDInt, ok := userID.(int)
	if !ok {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Invalid user ID"})
		return
	}
	
	conn, err := db.Connect()
	if err != nil {
		log.Printf("Database connection error: %s", strings.ReplaceAll(err.Error(), "\n", " "))
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Database error"})
		return
	}
	
	// Get fleet owner ID
	fleetOwner, err := services.GetFleetOwnerByUserID(conn, userIDInt)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Fleet owner profile not found"})
		return
	}
	
	vehicles, err := services.GetFleetVehicles(conn, fleetOwner.ID)
	if err != nil {
		log.Printf("Get fleet vehicles error: %s", strings.ReplaceAll(err.Error(), "\n", " "))
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get vehicles"})
		return
	}
	
	c.JSON(http.StatusOK, gin.H{"vehicles": vehicles})
}
func uploadDocumentHandler(c *gin.Context) {
	// Get file from form
	file, header, err := c.Request.FormFile("file")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "No file uploaded"})
		return
	}
	defer file.Close()

	// Get document type
	documentType := c.PostForm("document_type")
	if documentType == "" {
		documentType = "document"
	}

	// Validate file type
	allowedTypes := map[string]bool{
		".jpg":  true,
		".jpeg": true,
		".png":  true,
		".pdf":  true,
	}

	ext := strings.ToLower(filepath.Ext(header.Filename))
	if !allowedTypes[ext] {
		c.JSON(http.StatusBadRequest, gin.H{"error": "File type not allowed"})
		return
	}

	// Create uploads directory if not exists
	uploadDir := "./uploads"
	if err := os.MkdirAll(uploadDir, 0755); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create upload directory"})
		return
	}

	// Generate unique filename
	timestamp := time.Now().Unix()
	filename := fmt.Sprintf("%s_%d%s", documentType, timestamp, ext)
	filePath := filepath.Join(uploadDir, filename)

	// Create destination file
	dst, err := os.Create(filePath)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create file"})
		return
	}
	defer dst.Close()

	// Copy file content
	if _, err := io.Copy(dst, file); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to save file"})
		return
	}

	// Return file URL
	fileURL := fmt.Sprintf("/api/v1/files/%s", filename)
	c.JSON(http.StatusOK, gin.H{
		"message":  "File uploaded successfully",
		"file_url": fileURL,
		"filename": filename,
	})
}

func getApprovedVehiclesPublicHandler(c *gin.Context) {
	conn, err := db.Connect()
	if err != nil {
		log.Printf("Database connection error: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Database error"})
		return
	}

	vehicles, err := services.GetApprovedVehicles(conn)
	if err != nil {
		log.Printf("Get approved vehicles error: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get approved vehicles"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"vehicles": vehicles})
}
// Enhanced admin verification handlers

func getAdminVerificationDashboardHandler(c *gin.Context) {
	conn, err := db.Connect()
	if err != nil {
		log.Printf("Database connection error: %s", strings.ReplaceAll(err.Error(), "\n", " "))
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Database error"})
		return
	}

	// Simple implementation for verification dashboard
	dashboard := map[string]interface{}{
		"pending_count": 0,
		"needs_correction_count": 0,
		"under_review_count": 0,
		"approved_today": 0,
		"rejected_today": 0,
		"urgent_items": []map[string]interface{}{},
		"recent_submissions": []map[string]interface{}{},
	}

	// Get basic counts from database
	var pendingCount, needsCorrectionCount, underReviewCount, approvedToday, rejectedToday int
	
	// Count pending vehicles
	conn.QueryRow("SELECT COUNT(*) FROM vehicles WHERE verification_status = 'pending' OR verification_status = 'submitted'").Scan(&pendingCount)
	
	// Count needs correction
	conn.QueryRow("SELECT COUNT(*) FROM vehicles WHERE verification_status = 'needs_correction'").Scan(&needsCorrectionCount)
	
	// Count under review
	conn.QueryRow("SELECT COUNT(*) FROM vehicles WHERE verification_status = 'under_review'").Scan(&underReviewCount)
	
	// Count approved today
	conn.QueryRow("SELECT COUNT(*) FROM vehicles WHERE verification_status = 'approved' AND DATE(updated_at) = CURRENT_DATE").Scan(&approvedToday)
	
	// Count rejected today
	conn.QueryRow("SELECT COUNT(*) FROM vehicles WHERE verification_status = 'rejected' AND DATE(updated_at) = CURRENT_DATE").Scan(&rejectedToday)
	
	dashboard["pending_count"] = pendingCount
	dashboard["needs_correction_count"] = needsCorrectionCount
	dashboard["under_review_count"] = underReviewCount
	dashboard["approved_today"] = approvedToday
	dashboard["rejected_today"] = rejectedToday

	c.JSON(http.StatusOK, gin.H{"dashboard": dashboard})
}

func getVehiclesByStatusHandler(c *gin.Context) {
	status := c.Param("status")
	
	// Validate status parameter
	validStatuses := []string{"pending", "submitted", "needs_correction", "under_review", "pending_inspection", "approved", "rejected"}
	validStatus := false
	for _, vs := range validStatuses {
		if status == vs {
			validStatus = true
			break
		}
	}
	if !validStatus {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid status parameter"})
		return
	}

	conn, err := db.Connect()
	if err != nil {
		log.Printf("Database connection error: %s", strings.ReplaceAll(err.Error(), "\n", " "))
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Database error"})
		return
	}

	// Simple implementation to get vehicles by status
	query := `SELECT v.id, v.registration_number, v.vehicle_type, v.brand, v.model, v.year,
					 v.chassis_number, v.engine_number, v.color, v.capacity_weight,
					 v.ownership_status, v.verification_status, v.created_at, v.created_by,
					 u.username, u.email, u.full_name
			  FROM vehicles v
			  JOIN users u ON v.created_by = u.id
			  WHERE v.verification_status = $1
			  ORDER BY v.created_at DESC`

	rows, err := conn.Query(query, status)
	if err != nil {
		log.Printf("Query vehicles by status error: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get vehicles"})
		return
	}
	defer rows.Close()

	var vehicles []map[string]interface{}
	for rows.Next() {
		var vehicle map[string]interface{} = make(map[string]interface{})
		var id, createdBy, year int
		var registrationNumber, vehicleType, brand, model, chassisNumber, engineNumber, color, ownershipStatus, verificationStatus, username, email, fullName string
		var capacityWeight float64
		var createdAt time.Time

		err := rows.Scan(&id, &registrationNumber, &vehicleType, &brand, &model, &year,
			&chassisNumber, &engineNumber, &color, &capacityWeight,
			&ownershipStatus, &verificationStatus, &createdAt, &createdBy,
			&username, &email, &fullName)
		if err != nil {
			continue
		}

		vehicle["id"] = id
		vehicle["registration_number"] = registrationNumber
		vehicle["vehicle_type"] = vehicleType
		vehicle["brand"] = brand
		vehicle["model"] = model
		vehicle["year"] = year
		vehicle["chassis_number"] = chassisNumber
		vehicle["engine_number"] = engineNumber
		vehicle["color"] = color
		vehicle["capacity_weight"] = capacityWeight
		vehicle["ownership_status"] = ownershipStatus
		vehicle["verification_status"] = verificationStatus
		vehicle["created_at"] = createdAt
		vehicle["created_by"] = createdBy
		vehicle["owner_name"] = fullName
		vehicle["owner_email"] = email
		vehicle["username"] = username
		vehicle["days_waiting"] = int(time.Since(createdAt).Hours() / 24)

		vehicles = append(vehicles, vehicle)
	}

	c.JSON(http.StatusOK, gin.H{"vehicles": vehicles, "status": status, "count": len(vehicles)})
}

func requestCorrectionHandler(c *gin.Context) {
	vehicleIDStr := c.Param("id")
	vehicleID, err := strconv.Atoi(vehicleIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid vehicle ID"})
		return
	}

	var req struct {
		Notes           string   `json:"notes" binding:"required"`
		CorrectionItems []string `json:"correction_items" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request format"})
		return
	}

	conn, err := db.Connect()
	if err != nil {
		log.Printf("Database connection error: %s", strings.ReplaceAll(err.Error(), "\n", " "))
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Database error"})
		return
	}

	// Get admin user ID from context
	adminID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Admin authentication required"})
		return
	}

	adminIDInt, ok := adminID.(int)
	if !ok {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Invalid admin ID"})
		return
	}

	err = services.UpdateVehicleWithCorrection(conn, vehicleID, req.CorrectionItems, req.Notes, adminIDInt)
	if err != nil {
		log.Printf("Update vehicle correction error: %s", strings.ReplaceAll(err.Error(), "\n", " "))
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Send notification to vehicle owner
	go func() {
		notificationService := services.NewNotificationService(conn)
		extraVars := map[string]interface{}{
			"correction_items": strings.Join(req.CorrectionItems, ", "),
		}
		err := notificationService.SendVehicleNotification(vehicleID, "needs_correction", extraVars)
		if err != nil {
			log.Printf("Failed to send correction notification: %v", err)
		}
	}()

	c.JSON(http.StatusOK, gin.H{"message": "Correction request sent successfully"})
}

func performCrossCheckHandler(c *gin.Context) {
	vehicleIDStr := c.Param("id")
	vehicleID, err := strconv.Atoi(vehicleIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid vehicle ID"})
		return
	}

	var req struct {
		CheckType string `json:"check_type" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request format"})
		return
	}

	// Validate check type
	validCheckTypes := []string{"samsat", "kir", "insurance", "duplicate"}
	validCheckType := false
	for _, vct := range validCheckTypes {
		if req.CheckType == vct {
			validCheckType = true
			break
		}
	}
	if !validCheckType {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid check type"})
		return
	}

	conn, err := db.Connect()
	if err != nil {
		log.Printf("Database connection error: %s", strings.ReplaceAll(err.Error(), "\n", " "))
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Database error"})
		return
	}

	result, err := services.PerformCrossCheck(conn, vehicleID, req.CheckType)
	if err != nil {
		log.Printf("Cross-check error: %s", strings.ReplaceAll(err.Error(), "\n", " "))
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"result": result})
}

func scheduleInspectionHandler(c *gin.Context) {
	vehicleIDStr := c.Param("id")
	vehicleID, err := strconv.Atoi(vehicleIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid vehicle ID"})
		return
	}

	var req struct {
		InspectionDate string `json:"inspection_date" binding:"required"`
		Location       string `json:"location" binding:"required"`
		Notes          string `json:"notes"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request format"})
		return
	}

	// Parse inspection date
	inspectionDate, err := time.Parse("2006-01-02T15:04:05Z", req.InspectionDate)
	if err != nil {
		// Try alternative format
		inspectionDate, err = time.Parse("2006-01-02 15:04:05", req.InspectionDate)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid date format"})
			return
		}
	}

	conn, err := db.Connect()
	if err != nil {
		log.Printf("Database connection error: %s", strings.ReplaceAll(err.Error(), "\n", " "))
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Database error"})
		return
	}

	// Get admin user ID from context
	adminID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Admin authentication required"})
		return
	}

	adminIDInt, ok := adminID.(int)
	if !ok {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Invalid admin ID"})
		return
	}

	err = services.ScheduleInspection(conn, vehicleID, inspectionDate, req.Location, adminIDInt)
	if err != nil {
		log.Printf("Schedule inspection error: %s", strings.ReplaceAll(err.Error(), "\n", " "))
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Send notification to vehicle owner
	go func() {
		notificationService := services.NewNotificationService(conn)
		extraVars := map[string]interface{}{
			"date":     inspectionDate.Format("2006-01-02 15:04"),
			"location": req.Location,
		}
		err := notificationService.SendVehicleNotification(vehicleID, "inspection_scheduled", extraVars)
		if err != nil {
			log.Printf("Failed to send inspection notification: %v", err)
		}
	}()

	c.JSON(http.StatusOK, gin.H{
		"message": "Inspection scheduled successfully",
		"inspection_date": inspectionDate,
		"location": req.Location,
	})
}

// OCR handlers
func extractSTNKHandler(c *gin.Context) {
	var req struct {
		ImageData    string `json:"image_data" binding:"required"`
		DocumentType string `json:"document_type"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request format"})
		return
	}

	ocrService := services.NewOCRService()
	data, err := ocrService.ExtractSTNKData(req.ImageData)
	if err != nil {
		log.Printf("STNK OCR error: %v", err)
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Validate extracted data
	issues := ocrService.ValidateSTNKData(data)

	c.JSON(http.StatusOK, gin.H{
		"extracted_data": data,
		"validation_issues": issues,
		"status": "success",
	})
}

func extractKTPHandler(c *gin.Context) {
	var req struct {
		ImageData    string `json:"image_data" binding:"required"`
		DocumentType string `json:"document_type"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request format"})
		return
	}

	ocrService := services.NewOCRService()
	data, err := ocrService.ExtractKTPData(req.ImageData)
	if err != nil {
		log.Printf("KTP OCR error: %v", err)
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Validate extracted data
	issues := ocrService.ValidateKTPData(data)

	c.JSON(http.StatusOK, gin.H{
		"extracted_data": data,
		"validation_issues": issues,
		"status": "success",
	})
}

func faceMatchHandler(c *gin.Context) {
	var req struct {
		SelfieImage string `json:"selfie_image" binding:"required"`
		KTPImage    string `json:"ktp_image" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request format"})
		return
	}

	ocrService := services.NewOCRService()
	result, err := ocrService.PerformFaceMatch(req.SelfieImage, req.KTPImage)
	if err != nil {
		log.Printf("Face match error: %v", err)
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, result)
}

func validateQualityHandler(c *gin.Context) {
	var req struct {
		ImageData    string `json:"image_data" binding:"required"`
		DocumentType string `json:"document_type" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request format"})
		return
	}

	ocrService := services.NewOCRService()
	result, err := ocrService.ValidateDocumentQuality(req.ImageData, req.DocumentType)
	if err != nil {
		log.Printf("Quality validation error: %v", err)
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, result)
}

func uploadDocumentDirectHandler(c *gin.Context) {
	var req struct {
		DocumentType string `json:"document_type" binding:"required"`
		FileName     string `json:"file_name" binding:"required"`
		FileSize     int    `json:"file_size"`
		MimeType     string `json:"mime_type"`
		Data         string `json:"data" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request format"})
		return
	}

	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Authentication required"})
		return
	}

	userIDInt, ok := userID.(int)
	if !ok {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Invalid user ID"})
		return
	}

	conn, err := db.Connect()
	if err != nil {
		log.Printf("Database connection error: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Database error"})
		return
	}

	// Save file to uploads directory
	os.MkdirAll("./uploads", 0755)
	filePath := fmt.Sprintf("./uploads/%s", req.FileName)
	file, err := os.Create(filePath)
	if err == nil {
		file.WriteString(req.Data)
		file.Close()
	}

	// Save document record to database
	query := `INSERT INTO user_documents (user_id, document_type, file_name, file_path, file_size, mime_type, upload_status, created_at) 
			  VALUES ($1, $2, $3, $4, $5, $6, 'uploaded', NOW()) RETURNING id, created_at`

	var docID int
	var createdAt time.Time
	err = conn.QueryRow(query, userIDInt, req.DocumentType, req.FileName, filePath, req.FileSize, req.MimeType).
		Scan(&docID, &createdAt)

	if err != nil {
		log.Printf("Insert document error: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to save document"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"id": docID,
		"file_path": filePath,
		"file_name": req.FileName,
		"document_type": req.DocumentType,
		"upload_status": "uploaded",
		"created_at": createdAt,
	})
}

func getUploadedDocumentsHandler(c *gin.Context) {
	conn, err := db.Connect()
	if err != nil {
		log.Printf("Database connection error: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Database error"})
		return
	}

	query := `SELECT d.id, d.user_id, d.document_type, d.file_name, d.file_path, 
					 d.verification_status, d.created_at, u.username, u.email
			  FROM user_documents d 
			  JOIN users u ON d.user_id = u.id 
			  WHERE d.verification_status = 'pending'
			  ORDER BY d.created_at DESC`

	rows, err := conn.Query(query)
	if err != nil {
		log.Printf("Query documents error: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get documents"})
		return
	}
	defer rows.Close()

	var documents []map[string]interface{}
	for rows.Next() {
		var doc map[string]interface{} = make(map[string]interface{})
		var id, userID int
		var docType, fileName, filePath, status, username, email string
		var createdAt time.Time

		err := rows.Scan(&id, &userID, &docType, &fileName, &filePath, &status, &createdAt, &username, &email)
		if err != nil {
			continue
		}

		doc["id"] = id
		doc["user_id"] = userID
		doc["document_type"] = docType
		doc["file_name"] = fileName
		doc["file_path"] = filePath
		doc["verification_status"] = status
		doc["created_at"] = createdAt
		doc["username"] = username
		doc["email"] = email

		documents = append(documents, doc)
	}

	c.JSON(http.StatusOK, gin.H{"documents": documents})
}

func verifyDocumentHandler(c *gin.Context) {
	docIDStr := c.Param("id")
	docID, err := strconv.Atoi(docIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid document ID"})
		return
	}

	var req struct {
		Status string `json:"status" binding:"required"`
		Notes  string `json:"notes"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request format"})
		return
	}

	conn, err := db.Connect()
	if err != nil {
		log.Printf("Database connection error: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Database error"})
		return
	}

	query := `UPDATE user_documents SET verification_status = $1, verification_notes = $2, updated_at = NOW() WHERE id = $3`
	_, err = conn.Exec(query, req.Status, req.Notes, docID)
	if err != nil {
		log.Printf("Update document error: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update document"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Document verification updated"})
}

// GPS Registration handlers
func createGPSRegistrationHandler(c *gin.Context) {
	var req models.GPSRegistrationRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	conn, err := db.Connect()
	if err != nil {
		log.Printf("Database connection error: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Database error"})
		return
	}

	repo := repository.NewGPSRegistrationRepository(conn)
	registration, err := repo.Create(&req)
	if err != nil {
		log.Printf("Create GPS registration error: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create GPS registration"})
		return
	}

	c.JSON(http.StatusCreated, registration)
}

func getAllGPSRegistrationsHandler(c *gin.Context) {
	conn, err := db.Connect()
	if err != nil {
		log.Printf("Database connection error: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Database error"})
		return
	}

	repo := repository.NewGPSRegistrationRepository(conn)
	registrations, err := repo.GetAll()
	if err != nil {
		log.Printf("Get GPS registrations error: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get registrations"})
		return
	}

	c.JSON(http.StatusOK, registrations)
}

func getPendingGPSRegistrationsHandler(c *gin.Context) {
	conn, err := db.Connect()
	if err != nil {
		log.Printf("Database connection error: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Database error"})
		return
	}

	repo := repository.NewGPSRegistrationRepository(conn)
	registrations, err := repo.GetPending()
	if err != nil {
		log.Printf("Get pending GPS registrations error: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get pending registrations"})
		return
	}

	c.JSON(http.StatusOK, registrations)
}

func approveGPSRegistrationHandler(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.Atoi(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid ID"})
		return
	}

	var req models.GPSApprovalRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "User not authenticated"})
		return
	}

	conn, err := db.Connect()
	if err != nil {
		log.Printf("Database connection error: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Database error"})
		return
	}

	repo := repository.NewGPSRegistrationRepository(conn)
	err = repo.UpdateStatus(id, req.Status, req.AdminNotes, userID.(int))
	if err != nil {
		log.Printf("Update GPS registration status error: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update registration status"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Registration status updated successfully"})
}

func getGPSRegistrationByIDHandler(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.Atoi(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid ID"})
		return
	}

	conn, err := db.Connect()
	if err != nil {
		log.Printf("Database connection error: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Database error"})
		return
	}

	repo := repository.NewGPSRegistrationRepository(conn)
	registration, err := repo.GetByID(id)
	if err != nil {
		log.Printf("Get GPS registration error: %v", err)
		c.JSON(http.StatusNotFound, gin.H{"error": "Registration not found"})
		return
	}

	c.JSON(http.StatusOK, registration)
}