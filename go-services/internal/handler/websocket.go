package handler

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"sync"
	"time"

	"aureader-services/internal/storage"

	"github.com/coder/websocket"
	"github.com/coder/websocket/wsjson"
)

// WSHub manages all active WebSocket connections, keyed by user ID.
type WSHub struct {
	mu      sync.RWMutex
	clients map[int64]*wsClient
	redis   *storage.RedisClient
	pg      *storage.PostgresClient
}

type wsClient struct {
	conn   *websocket.Conn
	userID int64
	send   chan map[string]interface{}
	ctx    context.Context
	cancel context.CancelFunc
}

// NewWSHub creates a new WebSocket hub.
func NewWSHub(redis *storage.RedisClient, pg *storage.PostgresClient) *WSHub {
	return &WSHub{
		clients: make(map[int64]*wsClient),
		redis:   redis,
		pg:      pg,
	}
}

// HandleWS is the HTTP handler for the WebSocket upgrade endpoint (GET /ws).
func (h *WSHub) HandleWS(w http.ResponseWriter, r *http.Request) {
	// Authenticate via query param: /ws?token=1|abcdef...
	token := r.URL.Query().Get("token")
	if token == "" {
		http.Error(w, `{"error":"token query param required"}`, http.StatusUnauthorized)
		return
	}

	ctx, cancel := context.WithTimeout(r.Context(), 3*time.Second)
	userID, err := h.pg.ValidateToken(ctx, "Bearer "+token)
	cancel()
	if err != nil {
		http.Error(w, `{"error":"invalid token"}`, http.StatusUnauthorized)
		return
	}

	// Accept WebSocket connection
	conn, err := websocket.Accept(w, r, &websocket.AcceptOptions{
		InsecureSkipVerify: true, // Allow connections from any origin (dev)
	})
	if err != nil {
		log.Printf("[WS] Accept error: %v", err)
		return
	}

	clientCtx, clientCancel := context.WithCancel(context.Background())

	client := &wsClient{
		conn:   conn,
		userID: userID,
		send:   make(chan map[string]interface{}, 64),
		ctx:    clientCtx,
		cancel: clientCancel,
	}

	// Register client (replace old connection if exists)
	h.mu.Lock()
	if old, ok := h.clients[userID]; ok {
		old.cancel()
		old.conn.Close(websocket.StatusGoingAway, "replaced")
	}
	h.clients[userID] = client
	h.mu.Unlock()

	log.Printf("[WS] ✅ User %d connected (total: %d)", userID, h.Count())

	// Send welcome message
	client.send <- map[string]interface{}{
		"type":    "connected",
		"message": "Real-time notifications active",
		"user_id": userID,
	}

	// Start write pump
	go h.writePump(client)

	// Read pump (keeps connection alive, handles pings)
	h.readPump(client)

	// Cleanup
	h.mu.Lock()
	if c, ok := h.clients[userID]; ok && c == client {
		delete(h.clients, userID)
	}
	h.mu.Unlock()
	client.cancel()
	conn.Close(websocket.StatusNormalClosure, "bye")

	log.Printf("[WS] 👋 User %d disconnected (total: %d)", userID, h.Count())
}

// writePump sends messages from the send channel to the WebSocket.
func (h *WSHub) writePump(c *wsClient) {
	for {
		select {
		case <-c.ctx.Done():
			return
		case msg := <-c.send:
			ctx, cancel := context.WithTimeout(c.ctx, 5*time.Second)
			err := wsjson.Write(ctx, c.conn, msg)
			cancel()
			if err != nil {
				log.Printf("[WS] Write error for user %d: %v", c.userID, err)
				c.cancel()
				return
			}
		}
	}
}

// readPump reads messages from the WebSocket (mainly for keep-alive pings).
func (h *WSHub) readPump(c *wsClient) {
	for {
		_, _, err := c.conn.Read(c.ctx)
		if err != nil {
			return // Connection closed
		}
	}
}

// SendToUser sends a message to a specific user via WebSocket.
func (h *WSHub) SendToUser(userID int64, msg map[string]interface{}) bool {
	h.mu.RLock()
	client, ok := h.clients[userID]
	h.mu.RUnlock()

	if !ok {
		return false
	}

	select {
	case client.send <- msg:
		return true
	default:
		// Channel full, client is slow
		log.Printf("[WS] ⚠️  Send channel full for user %d, dropping message", userID)
		return false
	}
}

// Count returns the number of connected WebSocket clients.
func (h *WSHub) Count() int {
	h.mu.RLock()
	defer h.mu.RUnlock()
	return len(h.clients)
}

// StartRedisSubscriber listens for notification events from Redis pub/sub
// and routes them to the appropriate WebSocket client.
func (h *WSHub) StartRedisSubscriber(ctx context.Context) {
	go func() {
		log.Println("[WS-SUB] Starting Redis subscriber for channel: notifications")

		for {
			select {
			case <-ctx.Done():
				log.Println("[WS-SUB] Shutting down...")
				return
			default:
			}

			err := h.redis.Subscribe(ctx, "notifications", func(payload string) {
				var msg map[string]interface{}
				if err := json.Unmarshal([]byte(payload), &msg); err != nil {
					log.Printf("[WS-SUB] Malformed message: %v", err)
					return
				}

				// Extract user_id from the message
				userIDRaw, ok := msg["user_id"]
				if !ok {
					return
				}

				var userID int64
				switch v := userIDRaw.(type) {
				case float64:
					userID = int64(v)
				case int64:
					userID = v
				default:
					return
				}

				// Wrap as a notification event
				wsMsg := map[string]interface{}{
					"type": "notification",
					"data": msg,
				}

				if h.SendToUser(userID, wsMsg) {
					log.Printf("[WS-SUB] → Sent notification to user %d", userID)
				}
			})

			if err != nil && ctx.Err() == nil {
				log.Printf("[WS-SUB] Subscriber error: %v — reconnecting in 3s", err)
				time.Sleep(3 * time.Second)
			}
		}
	}()
}

// WSStatsHandler returns current WebSocket connection stats.
func WSStatsHandler(hub *WSHub) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		fmt.Fprintf(w, `{"connected_clients":%d}`, hub.Count())
	}
}
