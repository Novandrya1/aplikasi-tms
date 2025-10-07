package handlers

import (
	"database/sql"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/youruser/aplikasi-tms/backend/internal/models"
	"github.com/youruser/aplikasi-tms/backend/internal/services"
)

type VehicleHandler struct {
	db *sql.DB
}

func NewVehicleHandler(db *sql.DB) *VehicleHandler {
	return &VehicleHandler{db: db}
}

// GetVehicles returns all vehicles with optional filtering
func (h *VehicleHandler) GetVehicles(c *gin.Context) {
	vehicles, err := services.GetVehicles(h.db)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "Failed to fetch vehicles",
		})
		return
	}

	// Add owner information for each vehicle
	var enrichedVehicles []map[string]interface{}
	for _, vehicle := range vehicles {
		vehicleMap := map[string]interface{}{
			"id":                     vehicle.ID,
			"registration_number":    vehicle.RegistrationNumber,
			"vehicle_type":          vehicle.VehicleType,
			"brand":                 vehicle.Brand,
			"model":                 vehicle.Model,
			"year":                  vehicle.Year,
			"chassis_number":        vehicle.ChassisNumber,
			"engine_number":         vehicle.EngineNumber,
			"color":                 vehicle.Color,
			"capacity_weight":       vehicle.CapacityWeight,
			"capacity_volume":       vehicle.CapacityVolume,
			"ownership_status":      vehicle.OwnershipStatus,
			"operational_status":    vehicle.OperationalStatus,
			"verification_status":   vehicle.VerificationStatus,
			"verification_substatus": vehicle.VerificationSubstatus,
			"insurance_company":     vehicle.InsuranceCompany,
			"insurance_policy_number": vehicle.InsurancePolicyNumber,
			"insurance_expiry_date": vehicle.InsuranceExpiryDate,
			"last_maintenance_date": vehicle.LastMaintenanceDate,
			"next_maintenance_date": vehicle.NextMaintenanceDate,
			"maintenance_notes":     vehicle.MaintenanceNotes,
			"created_at":           vehicle.CreatedAt,
			"updated_at":           vehicle.UpdatedAt,
		}

		// Get owner information
		ownerInfo, err := h.getOwnerInfo(vehicle.CreatedBy)
		if err == nil && ownerInfo != nil {
			vehicleMap["owner_name"] = ownerInfo["name"]
			vehicleMap["owner_email"] = ownerInfo["email"]
			vehicleMap["owner_phone"] = ownerInfo["phone"]
			vehicleMap["owner_address"] = ownerInfo["address"]
			if ownerInfo["company_name"] != nil {
				vehicleMap["company_name"] = ownerInfo["company_name"]
				vehicleMap["company_address"] = ownerInfo["company_address"]
			}
		}

		enrichedVehicles = append(enrichedVehicles, vehicleMap)
	}

	c.JSON(http.StatusOK, gin.H{
		"vehicles": enrichedVehicles,
		"total":    len(enrichedVehicles),
	})
}

// GetVehicleByID returns a specific vehicle by ID
func (h *VehicleHandler) GetVehicleByID(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.Atoi(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "Invalid vehicle ID",
		})
		return
	}

	vehicle, err := services.GetVehicleByID(h.db, id)
	if err != nil {
		if err.Error() == "vehicle not found" {
			c.JSON(http.StatusNotFound, gin.H{
				"error": "Vehicle not found",
			})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "Failed to fetch vehicle",
		})
		return
	}

	// Get owner information
	ownerInfo, _ := h.getOwnerInfo(vehicle.CreatedBy)

	response := map[string]interface{}{
		"vehicle": vehicle,
		"owner_info": ownerInfo,
	}

	c.JSON(http.StatusOK, response)
}

// CreateVehicle creates a new vehicle
func (h *VehicleHandler) CreateVehicle(c *gin.Context) {
	var req models.VehicleRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "Invalid request data",
			"details": err.Error(),
		})
		return
	}

	// Get user ID from context (set by auth middleware)
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{
			"error": "User not authenticated",
		})
		return
	}

	vehicle, err := services.CreateVehicle(h.db, req, userID.(int))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "Failed to create vehicle",
			"details": err.Error(),
		})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"message": "Vehicle created successfully",
		"vehicle": vehicle,
	})
}

// UpdateVehicleStatus updates vehicle verification status
func (h *VehicleHandler) UpdateVehicleStatus(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.Atoi(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "Invalid vehicle ID",
		})
		return
	}

	var req models.VehicleVerificationRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "Invalid request data",
			"details": err.Error(),
		})
		return
	}

	// Update vehicle status
	query := `UPDATE vehicles SET 
		verification_status = $1, 
		verification_notes = $2,
		requires_inspection = $3,
		updated_at = NOW()
		WHERE id = $4`

	_, err = h.db.Exec(query, req.Status, req.Notes, req.RequiresInspection, id)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "Failed to update vehicle status",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Vehicle status updated successfully",
	})
}

// GetVehicleStats returns vehicle statistics
func (h *VehicleHandler) GetVehicleStats(c *gin.Context) {
	stats := make(map[string]interface{})

	// Total vehicles
	var total int
	err := h.db.QueryRow("SELECT COUNT(*) FROM vehicles").Scan(&total)
	if err != nil {
		total = 0
	}
	stats["total"] = total

	// By status
	statusQuery := `SELECT 
		COALESCE(verification_status, 'pending') as status, 
		COUNT(*) as count 
		FROM vehicles 
		GROUP BY verification_status`
	
	rows, err := h.db.Query(statusQuery)
	if err == nil {
		defer rows.Close()
		statusCounts := make(map[string]int)
		for rows.Next() {
			var status string
			var count int
			if err := rows.Scan(&status, &count); err == nil {
				statusCounts[status] = count
			}
		}
		stats["by_status"] = statusCounts
	}

	// By type
	typeQuery := `SELECT 
		COALESCE(vehicle_type, 'unknown') as type, 
		COUNT(*) as count 
		FROM vehicles 
		GROUP BY vehicle_type`
	
	rows, err = h.db.Query(typeQuery)
	if err == nil {
		defer rows.Close()
		typeCounts := make(map[string]int)
		for rows.Next() {
			var vehicleType string
			var count int
			if err := rows.Scan(&vehicleType, &count); err == nil {
				typeCounts[vehicleType] = count
			}
		}
		stats["by_type"] = typeCounts
	}

	c.JSON(http.StatusOK, stats)
}

// getOwnerInfo retrieves owner information from users table
func (h *VehicleHandler) getOwnerInfo(userID int) (map[string]interface{}, error) {
	query := `SELECT name, email, phone, address, company_name, company_address 
		FROM users WHERE id = $1`
	
	var name, email sql.NullString
	var phone, address, companyName, companyAddress sql.NullString
	
	err := h.db.QueryRow(query, userID).Scan(
		&name, &email, &phone, &address, &companyName, &companyAddress,
	)
	
	if err != nil {
		return nil, err
	}

	info := map[string]interface{}{
		"name":    name.String,
		"email":   email.String,
		"phone":   phone.String,
		"address": address.String,
	}

	if companyName.Valid && companyName.String != "" {
		info["company_name"] = companyName.String
		info["company_address"] = companyAddress.String
	}

	return info, nil
}