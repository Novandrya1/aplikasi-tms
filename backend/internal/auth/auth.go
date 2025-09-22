package auth

import (
	"database/sql"
	"errors"
	"os"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"golang.org/x/crypto/bcrypt"
	"github.com/youruser/aplikasi-tms/backend/internal/models"
)

type Claims struct {
	UserID   int    `json:"user_id"`
	Username string `json:"username"`
	Role     string `json:"role"`
	jwt.RegisteredClaims
}

// Cache JWT secret untuk performance
var jwtSecret string

func init() {
	jwtSecret = os.Getenv("JWT_SECRET")
	if jwtSecret == "" {
		jwtSecret = "default-jwt-secret-change-in-production"
	}
}

func HashPassword(password string) (string, error) {
	// Use cost 10 for better performance while maintaining security
	bytes, err := bcrypt.GenerateFromPassword([]byte(password), 10)
	return string(bytes), err
}

func CheckPassword(password, hash string) bool {
	err := bcrypt.CompareHashAndPassword([]byte(hash), []byte(password))
	return err == nil
}

func GenerateToken(userID int, username, role string) (string, error) {
	if jwtSecret == "" {
		return "", errors.New("JWT_SECRET not configured")
	}

	claims := Claims{
		UserID:   userID,
		Username: username,
		Role:     role,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(24 * time.Hour)),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
			Issuer:    "tms-backend",
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString([]byte(jwtSecret))
}

func ValidateToken(tokenString string) (*Claims, error) {
	if jwtSecret == "" {
		return nil, errors.New("JWT_SECRET not configured")
	}

	token, err := jwt.ParseWithClaims(tokenString, &Claims{}, func(token *jwt.Token) (interface{}, error) {
		// Validate signing method to prevent algorithm confusion attacks
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, errors.New("unexpected signing method")
		}
		return []byte(jwtSecret), nil
	})

	if err != nil {
		return nil, err
	}

	if claims, ok := token.Claims.(*Claims); ok && token.Valid {
		return claims, nil
	}

	return nil, errors.New("invalid token")
}

func CreateUser(db *sql.DB, req models.RegisterRequest) (*models.User, error) {
	// Check if user already exists
	var exists bool
	checkQuery := "SELECT EXISTS(SELECT 1 FROM users WHERE username = $1 OR email = $2)"
	err := db.QueryRow(checkQuery, req.Username, req.Email).Scan(&exists)
	if err != nil {
		return nil, err
	}
	if exists {
		return nil, errors.New("user already exists")
	}

	hashedPassword, err := HashPassword(req.Password)
	if err != nil {
		return nil, err
	}

	// Default role is user, can be overridden
	role := "user"
	if req.Role != "" {
		role = req.Role
	}

	query := `INSERT INTO users (username, email, password_hash, full_name, role) 
			  VALUES ($1, $2, $3, $4, $5) RETURNING id, created_at, updated_at`
	
	var user models.User
	err = db.QueryRow(query, req.Username, req.Email, hashedPassword, req.FullName, role).
		Scan(&user.ID, &user.CreatedAt, &user.UpdatedAt)
	
	if err != nil {
		return nil, err
	}

	user.Username = req.Username
	user.Email = req.Email
	user.FullName = req.FullName
	user.Role = role
	
	return &user, nil
}

func LoginUser(db *sql.DB, req models.LoginRequest) (*models.User, error) {
	// Database connection errors will be caught by the actual query
	
	// Allow login with either username or email
	query := `SELECT id, username, email, password_hash, full_name, role, created_at, updated_at 
			  FROM users WHERE username = $1 OR email = $1`
	
	var user models.User
	var passwordHash string
	
	err := db.QueryRow(query, req.Email).Scan(
		&user.ID, &user.Username, &user.Email, &passwordHash, 
		&user.FullName, &user.Role, &user.CreatedAt, &user.UpdatedAt)
	
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, errors.New("user not found")
		}
		return nil, errors.New("database error: " + err.Error())
	}

	if !CheckPassword(req.Password, passwordHash) {
		return nil, errors.New("invalid password")
	}

	return &user, nil
}