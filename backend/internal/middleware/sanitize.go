package middleware

import (
	"strings"
)

var logReplacer = strings.NewReplacer(
	"\n", " ",
	"\r", " ",
	"\t", " ",
)

// SanitizeForLog sanitizes input for safe logging
func SanitizeForLog(input string) string {
	// Remove newlines and carriage returns to prevent log injection
	sanitized := logReplacer.Replace(input)
	
	// Limit length to prevent log flooding
	if len(sanitized) > 100 {
		sanitized = sanitized[:100] + "..."
	}
	
	return sanitized
}