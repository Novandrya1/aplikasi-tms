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
		api.GET("/admin/vehicles/pending", middleware.AuthRequired(), middleware.AdminRequired(), getPendingVehiclesHandler)
		api.GET("/admin/vehicles", middleware.AuthRequired(), middleware.AdminRequired(), getAllVehiclesAdminHandler)
		api.GET("/admin/vehicles/:id", middleware.AuthRequired(), middleware.AdminRequired(), getVehicleDetailsAdminHandler)
		api.PUT("/admin/vehicles/:id/verify", middleware.AuthRequired(), middleware.AdminRequired(), verifyVehicleHandler)
		api.GET("/admin/vehicles/:id/history", middleware.AuthRequired(), middleware.AdminRequired(), getVehicleVerificationHistoryHandler)
		
		// Enhanced dashboard endpoints
		api.GET("/notifications", middleware.AuthRequired(), getNotificationsHandler)
		api.PUT("/notifications/:id/read", middleware.AuthRequired(), markNotificationReadHandler)
		api.GET("/fleet/tracking", middleware.AuthRequired(), getVehicleTrackingHandler)
		api.GET("/fleet/analytics", middleware.AuthRequired(), getRevenueAnalyticsHandler)
		
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

	attachmentStructs, err := services.GetVehicleAttachments(conn, vehicleID)
	// Convert to map format for JSON response
	var attachments []map[string]interface{}
	for _, att := range attachmentStructs {
		attMap := map[string]interface{}{
			"id":              att.ID,
			"vehicle_id":      att.VehicleID,
			"attachment_type": att.AttachmentType,
			"file_name":       att.FileName,
			"file_path":       att.FilePath,
			"file_size":       att.FileSize,
			"mime_type":       att.MimeType,
			"uploaded_at":     att.UploadedAt,
		}
		attachments = append(attachments, attMap)
	}
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

	vehicles, err := services.GetPendingVehicles(conn)
	if err != nil {
		log.Printf("Get pending vehicles error: %s", strings.ReplaceAll(err.Error(), "\n", " "))
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get pending vehicles"})
		return
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
	var req models.VehicleRegistrationRequest
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
	
	// Get fleet owner ID
	fleetOwner, err := services.GetFleetOwnerByUserID(conn, userIDInt)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "You must register as fleet owner first"})
		return
	}
	
	vehicle, err := services.RegisterVehicleForFleet(conn, req, fleetOwner.ID)
	if err != nil {
		log.Printf("Register fleet vehicle error: %s", strings.ReplaceAll(err.Error(), "\n", " "))
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	
	c.JSON(http.StatusCreated, gin.H{"vehicle": vehicle})
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
