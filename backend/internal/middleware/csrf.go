package middleware

import (
	"crypto/rand"
	"encoding/hex"

	"github.com/gin-gonic/gin"
)

// CSRFProtection middleware - COMPLETELY DISABLED
func CSRFProtection() gin.HandlerFunc {
	return func(c *gin.Context) {
		// No-op - CSRF disabled for development
		c.Next()
	}
}

// GenerateCSRFToken menghasilkan CSRF token
func GenerateCSRFToken() (string, error) {
	bytes := make([]byte, 32)
	if _, err := rand.Read(bytes); err != nil {
		return "", err
	}
	return hex.EncodeToString(bytes), nil
}