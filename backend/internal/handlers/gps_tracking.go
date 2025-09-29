package handlers

import (
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/youruser/aplikasi-tms/backend/internal/models"
	"github.com/youruser/aplikasi-tms/backend/internal/repository"
)

type GPSTrackingHandler struct {
	repo *repository.GPSTrackingRepository
}

func NewGPSTrackingHandler(repo *repository.GPSTrackingRepository) *GPSTrackingHandler {
	return &GPSTrackingHandler{repo: repo}
}

// Receive GPS data from devices
func (h *GPSTrackingHandler) IngestGPSData(c *gin.Context) {
	var req struct {
		DeviceID  string  `json:"device_id" binding:"required"`
		Latitude  float64 `json:"latitude" binding:"required"`
		Longitude float64 `json:"longitude" binding:"required"`
		Speed     float64 `json:"speed"`
		Timestamp string  `json:"timestamp"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Parse timestamp or use current time
	var timestamp time.Time
	if req.Timestamp != "" {
		if t, err := time.Parse(time.RFC3339, req.Timestamp); err == nil {
			timestamp = t
		} else {
			timestamp = time.Now()
		}
	} else {
		timestamp = time.Now()
	}

	trackingData := &models.GPSTrackingData{
		DeviceID:  req.DeviceID,
		Latitude:  req.Latitude,
		Longitude: req.Longitude,
		Speed:     req.Speed,
		Timestamp: timestamp,
	}

	err := h.repo.InsertTrackingData(trackingData)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to save tracking data"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "GPS data received successfully"})
}

// Get latest positions of all active vehicles
func (h *GPSTrackingHandler) GetLatestPositions(c *gin.Context) {
	positions, err := h.repo.GetLatestPositions()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get positions"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"positions": positions})
}

// Get tracking history for specific device
func (h *GPSTrackingHandler) GetTrackingHistory(c *gin.Context) {
	deviceID := c.Param("deviceId")
	hoursStr := c.DefaultQuery("hours", "24")
	
	hours, err := strconv.Atoi(hoursStr)
	if err != nil || hours < 1 || hours > 168 { // Max 1 week
		hours = 24
	}

	history, err := h.repo.GetTrackingHistory(deviceID, hours)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get tracking history"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"history": history})
}

// Batch GPS data ingestion for multiple devices
func (h *GPSTrackingHandler) BatchIngestGPSData(c *gin.Context) {
	var req struct {
		Data []struct {
			DeviceID  string  `json:"device_id" binding:"required"`
			Latitude  float64 `json:"latitude" binding:"required"`
			Longitude float64 `json:"longitude" binding:"required"`
			Speed     float64 `json:"speed"`
			Timestamp string  `json:"timestamp"`
		} `json:"data" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	successCount := 0
	for _, item := range req.Data {
		var timestamp time.Time
		if item.Timestamp != "" {
			if t, err := time.Parse(time.RFC3339, item.Timestamp); err == nil {
				timestamp = t
			} else {
				timestamp = time.Now()
			}
		} else {
			timestamp = time.Now()
		}

		trackingData := &models.GPSTrackingData{
			DeviceID:  item.DeviceID,
			Latitude:  item.Latitude,
			Longitude: item.Longitude,
			Speed:     item.Speed,
			Timestamp: timestamp,
		}

		if err := h.repo.InsertTrackingData(trackingData); err == nil {
			successCount++
		}
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Batch processing completed",
		"total":   len(req.Data),
		"success": successCount,
	})
}