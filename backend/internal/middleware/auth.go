package middleware

import (
	"log"
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/youruser/aplikasi-tms/backend/internal/auth"
)

// AuthRequired middleware for protected routes
func AuthRequired() gin.HandlerFunc {
	return func(c *gin.Context) {
		token := c.GetHeader("Authorization")
		if token == "" {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Authorization header required"})
			c.Abort()
			return
		}

		// Remove Bearer prefix
		if len(token) > 7 && strings.ToLower(token[:7]) == "bearer " {
			token = strings.TrimSpace(token[7:])
		}

		if token == "" {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid token format"})
			c.Abort()
			return
		}

		claims, err := auth.ValidateToken(token)
		if err != nil {
			// Log authentication failure for security monitoring
			clientIP := SanitizeForLog(c.ClientIP())
			userAgent := SanitizeForLog(c.GetHeader("User-Agent"))
			log.Printf("Authentication failed - IP: %s, User-Agent: %s, Error: %v", clientIP, userAgent, err)
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid or expired token"})
			c.Abort()
			return
		}

		// Set user info in context
		c.Set("user_id", claims.UserID)
		c.Set("username", claims.Username)
		c.Set("user_role", claims.Role)
		c.Next()
	}
}

// AdminRequired middleware for admin-only routes
func AdminRequired() gin.HandlerFunc {
	return func(c *gin.Context) {
		role, exists := c.Get("user_role")
		if !exists || role != "admin" {
			// Log unauthorized admin access attempt
			userID, _ := c.Get("user_id")
			username, _ := c.Get("username")
			
			// Safe type assertion untuk username
			var usernameStr string
			if uname, ok := username.(string); ok {
				usernameStr = uname
			} else {
				usernameStr = "unknown"
			}
			
			log.Printf("Unauthorized admin access attempt - UserID: %v, Username: %s, IP: %s", 
				userID, SanitizeForLog(usernameStr), SanitizeForLog(c.ClientIP()))
			c.JSON(http.StatusForbidden, gin.H{"error": "Admin access required"})
			c.Abort()
			return
		}
		c.Next()
	}
}