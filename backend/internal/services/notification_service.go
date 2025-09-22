package services

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"log"
	"strings"
)

type NotificationService struct {
	db *sql.DB
}

type NotificationData struct {
	UserID      int                    `json:"user_id"`
	TemplateKey string                 `json:"template_key"`
	Variables   map[string]interface{} `json:"variables"`
	Channels    []string               `json:"channels"`
}

func NewNotificationService(db *sql.DB) *NotificationService {
	return &NotificationService{db: db}
}

func (s *NotificationService) SendVehicleNotification(vehicleID int, templateKey string, extraVars map[string]interface{}) error {
	// Get vehicle and owner data
	vehicleData, err := s.getVehicleNotificationData(vehicleID)
	if err != nil {
		return fmt.Errorf("failed to get vehicle data: %v", err)
	}

	// Get notification template
	template, err := s.getNotificationTemplate(templateKey)
	if err != nil {
		return fmt.Errorf("failed to get template: %v", err)
	}

	// Prepare variables
	variables := map[string]interface{}{
		"plate":          vehicleData["registration_number"],
		"application_id": fmt.Sprintf("V-%d", vehicleID),
		"owner_name":     vehicleData["owner_name"],
	}

	// Add extra variables
	for k, v := range extraVars {
		variables[k] = v
	}

	// Send notification
	notification := NotificationData{
		UserID:      vehicleData["user_id"].(int),
		TemplateKey: templateKey,
		Variables:   variables,
		Channels:    template["channels"].([]string),
	}

	return s.processNotification(notification, template)
}

func (s *NotificationService) processNotification(data NotificationData, template map[string]interface{}) error {
	// Replace variables in message
	message := s.replaceVariables(template["message"].(string), data.Variables)
	title := s.replaceVariables(template["title"].(string), data.Variables)

	// Log notification (in production, send via email/SMS/push)
	log.Printf("NOTIFICATION [%s] to user %d: %s - %s", 
		strings.Join(data.Channels, ","), data.UserID, title, message)

	// Store notification in database
	return s.storeNotification(data.UserID, title, message, data.Channels)
}

func (s *NotificationService) replaceVariables(text string, variables map[string]interface{}) string {
	result := text
	for key, value := range variables {
		placeholder := fmt.Sprintf("{%s}", key)
		result = strings.ReplaceAll(result, placeholder, fmt.Sprintf("%v", value))
	}
	return result
}

func (s *NotificationService) getVehicleNotificationData(vehicleID int) (map[string]interface{}, error) {
	query := `SELECT v.registration_number, u.id as user_id, u.full_name as owner_name, u.email
			  FROM vehicles v
			  LEFT JOIN fleet_owners fo ON v.fleet_owner_id = fo.id
			  LEFT JOIN users u ON fo.user_id = u.id
			  WHERE v.id = $1`

	var regNumber, ownerName, email string
	var userID int

	err := s.db.QueryRow(query, vehicleID).Scan(&regNumber, &userID, &ownerName, &email)
	if err != nil {
		return nil, err
	}

	return map[string]interface{}{
		"registration_number": regNumber,
		"user_id":            userID,
		"owner_name":         ownerName,
		"email":              email,
	}, nil
}

func (s *NotificationService) getNotificationTemplate(templateKey string) (map[string]interface{}, error) {
	query := `SELECT title, message, channels FROM notification_templates WHERE template_key = $1`

	var title, message string
	var channelsJSON string

	err := s.db.QueryRow(query, templateKey).Scan(&title, &message, &channelsJSON)
	if err != nil {
		return nil, err
	}

	var channels []string
	json.Unmarshal([]byte(channelsJSON), &channels)

	return map[string]interface{}{
		"title":    title,
		"message":  message,
		"channels": channels,
	}, nil
}

func (s *NotificationService) storeNotification(userID int, title, message string, channels []string) error {
	query := `INSERT INTO notifications (user_id, title, message, channels, created_at)
			  VALUES ($1, $2, $3, $4, CURRENT_TIMESTAMP)`

	channelsJSON, _ := json.Marshal(channels)
	_, err := s.db.Exec(query, userID, title, message, string(channelsJSON))
	return err
}