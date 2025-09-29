package repository

import (
	"database/sql"
	"time"

	"github.com/youruser/aplikasi-tms/backend/internal/models"
)

type GPSRegistrationRepository struct {
	db *sql.DB
}

func NewGPSRegistrationRepository(db *sql.DB) *GPSRegistrationRepository {
	return &GPSRegistrationRepository{db: db}
}

func (r *GPSRegistrationRepository) GetDB() *sql.DB {
	return r.db
}

func (r *GPSRegistrationRepository) Create(req *models.GPSRegistrationRequest) (*models.GPSRegistration, error) {
	query := `
		INSERT INTO gps_registrations (registration_number, vehicle_type, capacity_tons, operator_notes)
		VALUES ($1, $2, $3, $4)
		RETURNING id, registration_number, vehicle_type, capacity_tons, status, operator_notes, COALESCE(admin_notes, ''), created_at, updated_at, approved_at, approved_by`
	
	var gps models.GPSRegistration
	err := r.db.QueryRow(query, req.RegistrationNumber, req.VehicleType, req.CapacityTons, req.OperatorNotes).
		Scan(&gps.ID, &gps.RegistrationNumber, &gps.VehicleType, &gps.CapacityTons, &gps.Status, &gps.OperatorNotes, &gps.AdminNotes, &gps.CreatedAt, &gps.UpdatedAt, &gps.ApprovedAt, &gps.ApprovedBy)
	if err != nil {
		return nil, err
	}
	return &gps, nil
}

func (r *GPSRegistrationRepository) GetAll() ([]models.GPSRegistration, error) {
	query := `SELECT id, registration_number, vehicle_type, capacity_tons, status, COALESCE(operator_notes, ''), COALESCE(admin_notes, ''), created_at, updated_at, approved_at, approved_by FROM gps_registrations ORDER BY created_at DESC`
	
	rows, err := r.db.Query(query)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	
	var registrations []models.GPSRegistration
	for rows.Next() {
		var gps models.GPSRegistration
		err := rows.Scan(&gps.ID, &gps.RegistrationNumber, &gps.VehicleType, &gps.CapacityTons, &gps.Status, &gps.OperatorNotes, &gps.AdminNotes, &gps.CreatedAt, &gps.UpdatedAt, &gps.ApprovedAt, &gps.ApprovedBy)
		if err != nil {
			return nil, err
		}
		registrations = append(registrations, gps)
	}
	return registrations, nil
}

func (r *GPSRegistrationRepository) GetByID(id int) (*models.GPSRegistration, error) {
	query := `SELECT id, registration_number, vehicle_type, capacity_tons, status, COALESCE(operator_notes, ''), COALESCE(admin_notes, ''), created_at, updated_at, approved_at, approved_by FROM gps_registrations WHERE id = $1`
	
	var gps models.GPSRegistration
	err := r.db.QueryRow(query, id).Scan(&gps.ID, &gps.RegistrationNumber, &gps.VehicleType, &gps.CapacityTons, &gps.Status, &gps.OperatorNotes, &gps.AdminNotes, &gps.CreatedAt, &gps.UpdatedAt, &gps.ApprovedAt, &gps.ApprovedBy)
	if err != nil {
		return nil, err
	}
	return &gps, nil
}

func (r *GPSRegistrationRepository) UpdateStatus(id int, status string, adminNotes string, approvedBy int) error {
	query := `
		UPDATE gps_registrations 
		SET status = $1, admin_notes = $2, approved_by = $3, approved_at = $4, updated_at = CURRENT_TIMESTAMP
		WHERE id = $5`
	
	var approvedAt *time.Time
	if status == "approved" {
		now := time.Now()
		approvedAt = &now
	}
	
	_, err := r.db.Exec(query, status, adminNotes, approvedBy, approvedAt, id)
	return err
}

func (r *GPSRegistrationRepository) GetPending() ([]models.GPSRegistration, error) {
	query := `SELECT id, registration_number, vehicle_type, capacity_tons, status, COALESCE(operator_notes, ''), COALESCE(admin_notes, ''), created_at, updated_at, approved_at, approved_by FROM gps_registrations WHERE status = 'pending' ORDER BY created_at ASC`
	
	rows, err := r.db.Query(query)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	
	var registrations []models.GPSRegistration
	for rows.Next() {
		var gps models.GPSRegistration
		err := rows.Scan(&gps.ID, &gps.RegistrationNumber, &gps.VehicleType, &gps.CapacityTons, &gps.Status, &gps.OperatorNotes, &gps.AdminNotes, &gps.CreatedAt, &gps.UpdatedAt, &gps.ApprovedAt, &gps.ApprovedBy)
		if err != nil {
			return nil, err
		}
		registrations = append(registrations, gps)
	}
	return registrations, nil
}