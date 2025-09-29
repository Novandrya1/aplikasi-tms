package repository

import (
	"database/sql"
	"time"

	"github.com/youruser/aplikasi-tms/backend/internal/models"
)

type GPSTrackingRepository struct {
	db *sql.DB
}

func NewGPSTrackingRepository(db *sql.DB) *GPSTrackingRepository {
	return &GPSTrackingRepository{db: db}
}

func (r *GPSTrackingRepository) InsertTrackingData(data *models.GPSTrackingData) error {
	query := `INSERT INTO gps_tracking (device_id, latitude, longitude, speed, timestamp) 
			  VALUES ($1, $2, $3, $4, $5)`
	
	_, err := r.db.Exec(query, data.DeviceID, data.Latitude, data.Longitude, data.Speed, data.Timestamp)
	
	// Update device last signal
	if err == nil {
		r.updateDeviceLastSignal(data.DeviceID, data.Timestamp)
	}
	
	return err
}

func (r *GPSTrackingRepository) GetLatestPositions() ([]map[string]interface{}, error) {
	query := `SELECT DISTINCT ON (d.device_id) 
			  d.device_id, d.vehicle_id, v.registration_number,
			  t.latitude, t.longitude, t.speed, t.timestamp,
			  d.status
			  FROM gps_devices d
			  LEFT JOIN gps_tracking t ON d.device_id = t.device_id
			  LEFT JOIN vehicles v ON d.vehicle_id = v.id
			  WHERE d.status = 'active' AND t.timestamp IS NOT NULL
			  ORDER BY d.device_id, t.timestamp DESC`
	
	rows, err := r.db.Query(query)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	
	var positions []map[string]interface{}
	for rows.Next() {
		var deviceID, registration string
		var vehicleID sql.NullInt64
		var latitude, longitude, speed float64
		var timestamp time.Time
		var status string
		
		err := rows.Scan(&deviceID, &vehicleID, &registration, &latitude, &longitude, &speed, &timestamp, &status)
		if err != nil {
			continue
		}
		
		position := map[string]interface{}{
			"device_id": deviceID,
			"vehicle_id": vehicleID.Int64,
			"registration_number": registration,
			"latitude": latitude,
			"longitude": longitude,
			"speed": speed,
			"timestamp": timestamp,
			"status": r.getVehicleStatus(speed, timestamp),
		}
		
		positions = append(positions, position)
	}
	
	return positions, nil
}

func (r *GPSTrackingRepository) GetTrackingHistory(deviceID string, hours int) ([]models.GPSTrackingData, error) {
	query := `SELECT device_id, latitude, longitude, speed, timestamp 
			  FROM gps_tracking 
			  WHERE device_id = $1 AND timestamp >= $2 
			  ORDER BY timestamp DESC LIMIT 100`
	
	since := time.Now().Add(-time.Duration(hours) * time.Hour)
	rows, err := r.db.Query(query, deviceID, since)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	
	var history []models.GPSTrackingData
	for rows.Next() {
		var data models.GPSTrackingData
		err := rows.Scan(&data.DeviceID, &data.Latitude, &data.Longitude, &data.Speed, &data.Timestamp)
		if err != nil {
			continue
		}
		history = append(history, data)
	}
	
	return history, nil
}

func (r *GPSTrackingRepository) updateDeviceLastSignal(deviceID string, timestamp time.Time) {
	query := `UPDATE gps_devices SET last_signal = $1 WHERE device_id = $2`
	r.db.Exec(query, timestamp, deviceID)
}

func (r *GPSTrackingRepository) getVehicleStatus(speed float64, lastUpdate time.Time) string {
	timeDiff := time.Since(lastUpdate)
	
	if timeDiff > 30*time.Minute {
		return "offline"
	} else if speed < 5 {
		return "stopped"
	} else {
		return "moving"
	}
}