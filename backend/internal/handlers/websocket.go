package handlers

import (
	"encoding/json"
	"log"
	"net/http"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/gorilla/websocket"
	"github.com/youruser/aplikasi-tms/backend/internal/repository"
)

var upgrader = websocket.Upgrader{
	CheckOrigin: func(r *http.Request) bool {
		return true // Allow all origins for development
	},
}

type Hub struct {
	clients    map[*websocket.Conn]bool
	broadcast  chan []byte
	register   chan *websocket.Conn
	unregister chan *websocket.Conn
	mutex      sync.RWMutex
}

var trackingHub = &Hub{
	clients:    make(map[*websocket.Conn]bool),
	broadcast:  make(chan []byte),
	register:   make(chan *websocket.Conn),
	unregister: make(chan *websocket.Conn),
}

func init() {
	go trackingHub.run()
}

func (h *Hub) run() {
	for {
		select {
		case conn := <-h.register:
			h.mutex.Lock()
			h.clients[conn] = true
			h.mutex.Unlock()
			log.Printf("WebSocket client connected. Total: %d", len(h.clients))

		case conn := <-h.unregister:
			h.mutex.Lock()
			if _, ok := h.clients[conn]; ok {
				delete(h.clients, conn)
				conn.Close()
			}
			h.mutex.Unlock()
			log.Printf("WebSocket client disconnected. Total: %d", len(h.clients))

		case message := <-h.broadcast:
			h.mutex.RLock()
			for conn := range h.clients {
				if err := conn.WriteMessage(websocket.TextMessage, message); err != nil {
					delete(h.clients, conn)
					conn.Close()
				}
			}
			h.mutex.RUnlock()
		}
	}
}

func HandleWebSocket(c *gin.Context) {
	conn, err := upgrader.Upgrade(c.Writer, c.Request, nil)
	if err != nil {
		log.Printf("WebSocket upgrade error: %v", err)
		return
	}

	trackingHub.register <- conn

	// Keep connection alive
	go func() {
		defer func() {
			trackingHub.unregister <- conn
		}()

		for {
			_, _, err := conn.ReadMessage()
			if err != nil {
				break
			}
		}
	}()
}

// Broadcast GPS updates to all connected clients
func BroadcastGPSUpdate(deviceID string, latitude, longitude, speed float64) {
	update := map[string]interface{}{
		"type":      "gps_update",
		"device_id": deviceID,
		"latitude":  latitude,
		"longitude": longitude,
		"speed":     speed,
		"timestamp": time.Now(),
	}

	data, err := json.Marshal(update)
	if err != nil {
		return
	}

	select {
	case trackingHub.broadcast <- data:
	default:
		// Channel is full, skip this update
	}
}

// Start periodic position broadcast
func StartPositionBroadcast(repo *repository.GPSTrackingRepository) {
	ticker := time.NewTicker(10 * time.Second) // Broadcast every 10 seconds
	go func() {
		for range ticker.C {
			positions, err := repo.GetLatestPositions()
			if err != nil {
				continue
			}

			broadcast := map[string]interface{}{
				"type":      "positions_update",
				"positions": positions,
				"timestamp": time.Now(),
			}

			data, err := json.Marshal(broadcast)
			if err != nil {
				continue
			}

			select {
			case trackingHub.broadcast <- data:
			default:
				// Channel is full, skip this update
			}
		}
	}()
}