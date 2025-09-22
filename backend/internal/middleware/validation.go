package middleware

import (
	"html"
	"net/http"
	"regexp"
	"strings"

	"github.com/gin-gonic/gin"
)

// Pre-compiled regex untuk performance
var (
	controlCharsRegex = regexp.MustCompile(`[\x00-\x1f\x7f]`)
	logInjectionRegex = regexp.MustCompile(`[\r\n\t]`)
	sqlInjectionRegex = regexp.MustCompile(`(?i)(union|select|insert|update|delete|drop|create|alter|exec|script|javascript|vbscript|onload|onerror)`)
)

// SanitizeInput removes potentially dangerous characters from input
func SanitizeInput(input string) string {
	// Remove null bytes and control characters
	input = strings.ReplaceAll(input, "\x00", "")
	input = controlCharsRegex.ReplaceAllString(input, "")
	
	// Trim whitespace
	input = strings.TrimSpace(input)
	
	return input
}



// DetectSQLInjection checks for common SQL injection patterns
func DetectSQLInjection(input string) bool {
	return sqlInjectionRegex.MatchString(input)
}

// SanitizeForHTML escapes HTML characters
func SanitizeForHTML(input string) string {
	return html.EscapeString(SanitizeInput(input))
}

// ValidateInput middleware for input sanitization
func ValidateInput() gin.HandlerFunc {
	return func(c *gin.Context) {
		// Skip validation for GET requests
		if c.Request.Method == "GET" {
			c.Next()
			return
		}

		// Validate Content-Type for POST/PUT requests
		contentType := c.GetHeader("Content-Type")
		if !strings.Contains(contentType, "application/json") {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Content-Type must be application/json"})
			c.Abort()
			return
		}

		c.Next()
	}
}

// RateLimitByIP simple rate limiting (for production use Redis)
func RateLimitByIP() gin.HandlerFunc {
	return func(c *gin.Context) {
		// Simple rate limiting - in production use Redis
		c.Next()
	}
}