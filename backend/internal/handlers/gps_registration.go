package handlers

import (
	"fmt"
	"log"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/youruser/aplikasi-tms/backend/internal/models"
	"github.com/youruser/aplikasi-tms/backend/internal/repository"
)

type GPSRegistrationHandler struct {
	repo *repository.GPSRegistrationRepository
}

func NewGPSRegistrationHandler(repo *repository.GPSRegistrationRepository) *GPSRegistrationHandler {
	return &GPSRegistrationHandler{repo: repo}
}

func (h *GPSRegistrationHandler) CreateRegistration(c *gin.Context) {
	var req models.GPSRegistrationRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	registration, err := h.repo.Create(&req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create GPS registration"})
		return
	}

	c.JSON(http.StatusCreated, registration)
}

func (h *GPSRegistrationHandler) GetAllRegistrations(c *gin.Context) {
	registrations, err := h.repo.GetAll()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get registrations"})
		return
	}

	c.JSON(http.StatusOK, registrations)
}

func (h *GPSRegistrationHandler) GetPendingRegistrations(c *gin.Context) {
	registrations, err := h.repo.GetPending()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get pending registrations"})
		return
	}

	c.JSON(http.StatusOK, registrations)
}

func (h *GPSRegistrationHandler) ApproveRegistration(c *gin.Context) {
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

	// Get user ID from context (set by auth middleware)
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "User not authenticated"})
		return
	}

	err = h.repo.UpdateStatus(id, req.Status, req.AdminNotes, userID.(int))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update registration status"})
		return
	}

	// If approved, create GPS device
	if req.Status == "approved" {
		deviceID := fmt.Sprintf("GPS%06d", id)
		deviceRepo := repository.NewGPSDeviceRepository(h.repo.GetDB())
		_, err = deviceRepo.CreateDevice(id, deviceID)
		if err != nil {
			// Log error but don't fail the approval
			log.Printf("Failed to create GPS device: %v", err)
		}
	}

	c.JSON(http.StatusOK, gin.H{"message": "Registration status updated successfully"})
}

func (h *GPSRegistrationHandler) GetRegistrationByID(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.Atoi(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid ID"})
		return
	}

	registration, err := h.repo.GetByID(id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Registration not found"})
		return
	}

	c.JSON(http.StatusOK, registration)
}