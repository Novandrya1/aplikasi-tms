package config

import (
	"fmt"
	"os"
	"strconv"
	"strings"
)

type SecurityConfig struct {
	JWTSecret        string
	CSRFSecret       string
	AllowedOrigins   []string
	BCryptCost       int
	TokenExpiration  int // hours
	MaxLoginAttempts int
	RateLimitRPM     int // requests per minute
}

func LoadSecurityConfig() (*SecurityConfig, error) {
	// Production mode check removed - not used
	
	// JWT Secret - must be set in all environments
	jwtSecret := os.Getenv("JWT_SECRET")
	if jwtSecret == "" {
		return nil, fmt.Errorf("JWT_SECRET environment variable is required")
	}

	// CSRF Secret - must be set in all environments
	csrfSecret := os.Getenv("CSRF_SECRET")
	if csrfSecret == "" {
		return nil, fmt.Errorf("CSRF_SECRET environment variable is required")
	}

	// Allowed Origins
	allowedOriginsStr := os.Getenv("ALLOWED_ORIGINS")
	if allowedOriginsStr == "" {
		allowedOriginsStr = "http://localhost:3000,http://localhost:3001,http://localhost:3005,http://localhost:3006"
	}
	allowedOrigins := strings.Split(allowedOriginsStr, ",")

	// BCrypt Cost
	bcryptCost := 12
	if costStr := os.Getenv("BCRYPT_COST"); costStr != "" {
		if cost, err := strconv.Atoi(costStr); err == nil && cost >= 10 && cost <= 15 {
			bcryptCost = cost
		}
	}

	// Token Expiration (hours)
	tokenExpiration := 24
	if expStr := os.Getenv("TOKEN_EXPIRATION_HOURS"); expStr != "" {
		if exp, err := strconv.Atoi(expStr); err == nil && exp > 0 {
			tokenExpiration = exp
		}
	}

	// Max Login Attempts
	maxLoginAttempts := 5
	if attemptsStr := os.Getenv("MAX_LOGIN_ATTEMPTS"); attemptsStr != "" {
		if attempts, err := strconv.Atoi(attemptsStr); err == nil && attempts > 0 {
			maxLoginAttempts = attempts
		}
	}

	// Rate Limit (requests per minute)
	rateLimitRPM := 60
	if rpmStr := os.Getenv("RATE_LIMIT_RPM"); rpmStr != "" {
		if rpm, err := strconv.Atoi(rpmStr); err == nil && rpm > 0 {
			rateLimitRPM = rpm
		}
	}

	return &SecurityConfig{
		JWTSecret:        jwtSecret,
		CSRFSecret:       csrfSecret,
		AllowedOrigins:   allowedOrigins,
		BCryptCost:       bcryptCost,
		TokenExpiration:  tokenExpiration,
		MaxLoginAttempts: maxLoginAttempts,
		RateLimitRPM:     rateLimitRPM,
	}, nil
}