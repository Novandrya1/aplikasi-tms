package db

import (
	"database/sql"
	"fmt"
	"os"
	"sync"
	"time"

	_ "github.com/lib/pq"
)

var (
	db   *sql.DB
	once sync.Once
	mu   sync.Mutex
)

// GetDB returns singleton database connection
func GetDB() (*sql.DB, error) {
	var err error
	once.Do(func() {
		db, err = initDB()
	})
	return db, err
}

// Connect maintains backward compatibility with connection health check
func Connect() (*sql.DB, error) {
	db, err := GetDB()
	if err != nil {
		return nil, err
	}
	
	// Health check - if connection is dead, recreate it
	if err := db.Ping(); err != nil {
		// Thread-safe singleton reset
		mu.Lock()
		defer mu.Unlock()
		// Double-check pattern to prevent race condition
		if db != nil {
			db.Close()
			db = nil
			once = sync.Once{}
		}
		mu.Unlock()
		return GetDB()
	}
	
	return db, nil
}

func initDB() (*sql.DB, error) {
	host := os.Getenv("DB_HOST")
	if host == "" {
		host = "localhost"
	}
	
	port := os.Getenv("DB_PORT")
	if port == "" {
		port = "5432"
	}
	
	user := os.Getenv("DB_USER")
	if user == "" {
		return nil, fmt.Errorf("DB_USER environment variable is required")
	}
	
	password := os.Getenv("DB_PASSWORD")
	if password == "" {
		return nil, fmt.Errorf("DB_PASSWORD environment variable is required")
	}
	
	dbname := os.Getenv("DB_NAME")
	if dbname == "" {
		dbname = "tms_db"
	}

	sslMode := os.Getenv("DB_SSLMODE")
	if sslMode == "" {
		sslMode = "disable"
	}
	
	psqlInfo := fmt.Sprintf("host=%s port=%s user=%s password=%s dbname=%s sslmode=%s",
		host, port, user, password, dbname, sslMode)

	connection, err := sql.Open("postgres", psqlInfo)
	if err != nil {
		return nil, err
	}

	// Production-optimized connection pool settings
	connection.SetMaxOpenConns(25)  // Reduced for stability
	connection.SetMaxIdleConns(5)   // Reduced idle connections
	connection.SetConnMaxLifetime(5 * time.Minute)  // Shorter lifetime
	connection.SetConnMaxIdleTime(2 * time.Minute)  // Shorter idle time

	if err = connection.Ping(); err != nil {
		connection.Close()
		return nil, err
	}

	return connection, nil
}