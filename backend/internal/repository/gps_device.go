package repository

import (
	"database/sql"

	"github.com/youruser/aplikasi-tms/backend/internal/models"
)

type GPSDeviceRepository struct {
	db *sql.DB
}

func NewGPSDeviceRepository(db *sql.DB) *GPSDeviceRepository {
	return &GPSDeviceRepository{db: db}
}

func (r *GPSDeviceRepository) CreateDevice(registrationID int, deviceID string) (*models.GPSDevice, error) {
	query := `INSERT INTO gps_devices (device_id, registration_id, status) 
			  VALUES ($1, $2, 'pending_installation') 
			  RETURNING id, device_id, registration_id, status, created_at, updated_at`
	
	var device models.GPSDevice
	err := r.db.QueryRow(query, deviceID, registrationID).
		Scan(&device.ID, &device.DeviceID, &device.RegistrationID, &device.Status, &device.CreatedAt, &device.UpdatedAt)
	
	return &device, err
}

func (r *GPSDeviceRepository) GetAllDevices() ([]models.GPSDevice, error) {
	query := `SELECT d.id, d.device_id, d.vehicle_id, d.registration_id, d.status, 
			  d.installed_date, d.last_signal, d.created_at, d.updated_at,
			  v.registration_number
			  FROM gps_devices d
			  LEFT JOIN vehicles v ON d.vehicle_id = v.id
			  ORDER BY d.created_at DESC`
	
	rows, err := r.db.Query(query)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	
	var devices []models.GPSDevice
	for rows.Next() {
		var device models.GPSDevice
		var vehicleReg sql.NullString
		
		err := rows.Scan(&device.ID, &device.DeviceID, &device.VehicleID, &device.RegistrationID, 
			&device.Status, &device.InstalledDate, &device.LastSignal, &device.CreatedAt, &device.UpdatedAt, &vehicleReg)
		if err != nil {
			continue
		}
		
		devices = append(devices, device)
	}
	
	return devices, nil
}

func (r *GPSDeviceRepository) AssignToVehicle(deviceID string, vehicleID int) error {
	query := `UPDATE gps_devices SET vehicle_id = $1, status = 'installed', 
			  installed_date = CURRENT_TIMESTAMP, updated_at = CURRENT_TIMESTAMP 
			  WHERE device_id = $2`
	
	_, err := r.db.Exec(query, vehicleID, deviceID)
	return err
}

func (r *GPSDeviceRepository) UpdateStatus(deviceID string, status string) error {
	query := `UPDATE gps_devices SET status = $1, updated_at = CURRENT_TIMESTAMP WHERE device_id = $2`
	_, err := r.db.Exec(query, status, deviceID)
	return err
}