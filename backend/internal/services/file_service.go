package services

import (
	"database/sql"
	"fmt"
	"io"
	"mime/multipart"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/youruser/aplikasi-tms/backend/internal/middleware"
	"github.com/youruser/aplikasi-tms/backend/internal/models"
)

const (
	MaxFileSize = 10 << 20 // 10MB
	UploadDir   = "./uploads"
)

var allowedTypes = map[string]bool{
	"image/jpeg": true,
	"image/jpg":  true,
	"image/png":  true,
	"application/pdf": true,
}

var allowedAttachmentTypes = []string{
	"stnk", "bpkb", "uji_kir", "asuransi", 
	"foto_depan", "foto_belakang", "foto_samping",
}

func init() {
	// Create upload directory if not exists
	os.MkdirAll(UploadDir, 0750)
}

func UploadVehicleAttachment(db *sql.DB, vehicleID int, attachmentType string, file multipart.File, header *multipart.FileHeader) (*models.VehicleAttachment, error) {
	// Validate attachment type
	validType := false
	for _, t := range allowedAttachmentTypes {
		if t == attachmentType {
			validType = true
			break
		}
	}
	if !validType {
		return nil, fmt.Errorf("invalid attachment type: %s", attachmentType)
	}

	// Validate file size
	if header.Size > MaxFileSize {
		return nil, fmt.Errorf("file size exceeds limit of %d bytes", MaxFileSize)
	}

	// Validate file type
	contentType := header.Header.Get("Content-Type")
	if !allowedTypes[contentType] {
		return nil, fmt.Errorf("file type not allowed: %s", contentType)
	}

	// Generate secure filename without using user input directly
	baseFilename := filepath.Base(header.Filename)
	// Only use the extension, not the filename itself
	ext := filepath.Ext(baseFilename)
	// Validate extension is safe
	if strings.Contains(ext, "..") || strings.Contains(ext, "/") || strings.Contains(ext, "\\") || len(ext) > 10 {
		ext = ".tmp" // Default safe extension
	}
	// Generate completely new filename to avoid any path traversal
	filename := fmt.Sprintf("%d_%s_%d%s", vehicleID, attachmentType, time.Now().UnixNano(), ext)
	
	// Double-check generated filename is safe
	if strings.Contains(filename, "..") || strings.Contains(filename, "/") || strings.Contains(filename, "\\") {
		return nil, fmt.Errorf("invalid generated filename")
	}
	
	// Use only the filename, not any path from user input
	filePath := filepath.Join(UploadDir, filepath.Base(filename))
	
	// Validate final path is within upload directory
	absUploadDir, err := filepath.Abs(UploadDir)
	if err != nil {
		return nil, fmt.Errorf("failed to resolve upload directory: %v", err)
	}
	absFilePath, err := filepath.Abs(filePath)
	if err != nil {
		return nil, fmt.Errorf("failed to resolve file path: %v", err)
	}
	if !strings.HasPrefix(absFilePath, absUploadDir+string(filepath.Separator)) && absFilePath != absUploadDir {
		return nil, fmt.Errorf("path traversal detected")
	}

	// Create file
	dst, err := os.Create(filePath)
	if err != nil {
		return nil, fmt.Errorf("failed to create file: %v", err)
	}
	defer dst.Close()

	// Copy file content
	_, err = io.Copy(dst, file)
	if err != nil {
		os.Remove(filePath) // Clean up on error
		return nil, fmt.Errorf("failed to save file: %v", err)
	}

	// Save to database
	query := `INSERT INTO vehicle_attachments (vehicle_id, attachment_type, file_name, file_path, file_size, mime_type)
			  VALUES ($1, $2, $3, $4, $5, $6) RETURNING id, uploaded_at`

	var attachment models.VehicleAttachment
	err = db.QueryRow(query, vehicleID, attachmentType, header.Filename, filePath, header.Size, contentType).
		Scan(&attachment.ID, &attachment.UploadedAt)

	if err != nil {
		os.Remove(filePath) // Clean up on error
		return nil, fmt.Errorf("failed to save attachment record: %v", err)
	}

	attachment.VehicleID = vehicleID
	attachment.AttachmentType = attachmentType
	attachment.FileName = header.Filename
	attachment.FilePath = filePath
	attachment.FileSize = int(header.Size)
	attachment.MimeType = contentType

	return &attachment, nil
}

func GetVehicleAttachments(db *sql.DB, vehicleID int) ([]models.VehicleAttachment, error) {
	query := `SELECT id, vehicle_id, attachment_type, file_name, file_path, file_size, mime_type, uploaded_at
			  FROM vehicle_attachments WHERE vehicle_id = $1 ORDER BY uploaded_at DESC`

	rows, err := db.Query(query, vehicleID)
	if err != nil {
		return nil, fmt.Errorf("failed to get attachments: %v", err)
	}
	defer rows.Close()

	var attachments []models.VehicleAttachment
	for rows.Next() {
		var a models.VehicleAttachment
		err := rows.Scan(&a.ID, &a.VehicleID, &a.AttachmentType, &a.FileName, &a.FilePath, &a.FileSize, &a.MimeType, &a.UploadedAt)
		if err != nil {
			return nil, fmt.Errorf("failed to scan attachment: %v", err)
		}
		attachments = append(attachments, a)
	}

	return attachments, nil
}

func DeleteVehicleAttachment(db *sql.DB, attachmentID int, vehicleID int) error {
	// Get file path first
	var filePath string
	err := db.QueryRow("SELECT file_path FROM vehicle_attachments WHERE id = $1 AND vehicle_id = $2", 
		attachmentID, vehicleID).Scan(&filePath)
	if err != nil {
		if err == sql.ErrNoRows {
			return fmt.Errorf("attachment not found")
		}
		return fmt.Errorf("failed to get attachment: %v", err)
	}

	// Delete from database
	_, err = db.Exec("DELETE FROM vehicle_attachments WHERE id = $1 AND vehicle_id = $2", attachmentID, vehicleID)
	if err != nil {
		return fmt.Errorf("failed to delete attachment record: %v", err)
	}

	// Delete file
	if err := os.Remove(filePath); err != nil {
		// Log error but don't fail the operation
		fmt.Printf("Warning: failed to delete file %s: %v\n", middleware.SanitizeForLog(filePath), middleware.SanitizeForLog(err.Error()))
	}

	return nil
}