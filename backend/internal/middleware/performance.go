package middleware

import (
	"fmt"
	"log"
	"time"

	"github.com/gin-gonic/gin"
)

// RequestLogger logs request duration and details
func RequestLogger() gin.HandlerFunc {
	return gin.LoggerWithFormatter(func(param gin.LogFormatterParams) string {
		return fmt.Sprintf("%s - [%s] \"%s %s %s %d %s \"%s\" %s\"\n",
			SanitizeForLog(param.ClientIP),
			param.TimeStamp.Format(time.RFC1123),
			SanitizeForLog(param.Method),
			SanitizeForLog(param.Path),
			SanitizeForLog(param.Request.Proto),
			param.StatusCode,
			param.Latency,
			SanitizeForLog(param.Request.UserAgent()),
			SanitizeForLog(param.ErrorMessage),
		)
	})
}

// PerformanceMonitor tracks slow requests
func PerformanceMonitor() gin.HandlerFunc {
	return func(c *gin.Context) {
		start := time.Now()
		c.Next()
		
		duration := time.Since(start)
		if duration > 1*time.Second {
			log.Printf("SLOW REQUEST: %s %s took %v", 
				SanitizeForLog(c.Request.Method), 
				SanitizeForLog(c.Request.URL.Path), 
				duration)
		}
	}
}

// CompressionHeaders sets compression-related headers
func CompressionHeaders() gin.HandlerFunc {
	return func(c *gin.Context) {
		// Set compression headers for client negotiation
		c.Header("Vary", "Accept-Encoding")
		c.Next()
	}
}