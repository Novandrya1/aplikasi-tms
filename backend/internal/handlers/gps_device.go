package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/youruser/aplikasi-tms/backend/internal/repository"
)

type GPSDeviceHandler struct {
	repo *repository.GPSDeviceRepository
}

func NewGPSDeviceHandler(repo *repository.GPSDeviceRepository) *GPSDeviceHandler {
	return &GPSDeviceHandler{repo: repo}
}

func (h *GPSDeviceHandler) GetAllDevices(c *gin.Context) {
	devices, err := h.repo.GetAllDevices()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get devices"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"devices": devices})
}

func (h *GPSDeviceHandler) AssignDevice(c *gin.Context) {
	var req struct {
		DeviceID  string `json:"device_id" binding:"required"`
		VehicleID int    `json:"vehicle_id" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	err := h.repo.AssignToVehicle(req.DeviceID, req.VehicleID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to assign device"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Device assigned successfully"})
}

func (h *GPSDeviceHandler) UpdateDeviceStatus(c *gin.Context) {
	deviceID := c.Param("deviceId")
	
	var req struct {
		Status string `json:"status" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	err := h.repo.UpdateStatus(deviceID, req.Status)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update status"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Status updated successfully"})
}