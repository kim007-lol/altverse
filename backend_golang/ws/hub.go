package ws

import (
	"context"
	"encoding/json"
	"log"
	"net/http"
	"sync"
	"time"

	"aureader/backend/helper"

	"github.com/coder/websocket"
	"github.com/coder/websocket/wsjson"
	"github.com/gin-gonic/gin"
	"github.com/redis/go-redis/v9"
)

type wsClient struct {
	conn   *websocket.Conn
	userID uint64
	send   chan map[string]interface{}
	ctx    context.Context
	cancel context.CancelFunc
}

// Hub manages all active WebSocket connections keyed by user ID.
type Hub struct {
	mu      sync.RWMutex
	clients map[uint64]*wsClient
	redis   *redis.Client
}

func NewHub(rdb *redis.Client) *Hub {
	return &Hub{
		clients: make(map[uint64]*wsClient),
		redis:   rdb,
	}
}

// GinHandler returns a Gin-compatible handler for GET /ws.
// Auth via JWT Bearer query param: /ws?token=<JWT>
func (h *Hub) GinHandler() gin.HandlerFunc {
	return func(c *gin.Context) {
		token := c.Query("token")
		if token == "" {
			helper.Unauthorized(c, "token query param required")
			return
		}

		claims, err := helper.ParseToken(token)
		if err != nil {
			helper.Unauthorized(c, "invalid or expired token")
			return
		}
		userID := uint64(claims.UserID)

		conn, err := websocket.Accept(c.Writer, c.Request, &websocket.AcceptOptions{
			InsecureSkipVerify: true,
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

		h.mu.Lock()
		if old, ok := h.clients[userID]; ok {
			old.cancel()
			old.conn.Close(websocket.StatusGoingAway, "replaced")
		}
		h.clients[userID] = client
		h.mu.Unlock()

		log.Printf("[WS] ✅ User %d connected (total: %d)", userID, h.Count())

		client.send <- map[string]interface{}{
			"type":    "connected",
			"message": "Real-time notifications active",
			"user_id": userID,
		}

		go h.writePump(client)
		h.readPump(client)

		h.mu.Lock()
		if c2, ok := h.clients[userID]; ok && c2 == client {
			delete(h.clients, userID)
		}
		h.mu.Unlock()
		client.cancel()
		conn.Close(websocket.StatusNormalClosure, "bye")

		log.Printf("[WS] 👋 User %d disconnected (total: %d)", userID, h.Count())
	}
}

func (h *Hub) writePump(c *wsClient) {
	for {
		select {
		case <-c.ctx.Done():
			return
		case msg := <-c.send:
			ctx, cancel := context.WithTimeout(c.ctx, 5*time.Second)
			err := wsjson.Write(ctx, c.conn, msg)
			cancel()
			if err != nil {
				c.cancel()
				return
			}
		}
	}
}

func (h *Hub) readPump(c *wsClient) {
	for {
		if _, _, err := c.conn.Read(c.ctx); err != nil {
			return
		}
	}
}

// SendToUser pushes a message to a connected user. Returns false if not connected.
func (h *Hub) SendToUser(userID uint64, msg map[string]interface{}) bool {
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
		log.Printf("[WS] ⚠️  Send channel full for user %d, dropping", userID)
		return false
	}
}

// Count returns the number of connected clients.
func (h *Hub) Count() int {
	h.mu.RLock()
	defer h.mu.RUnlock()
	return len(h.clients)
}

// StartRedisSubscriber listens on the "notifications" pub/sub channel
// and routes messages to the appropriate WebSocket client.
func (h *Hub) StartRedisSubscriber(ctx context.Context) {
	go func() {
		log.Println("[WS-SUB] Starting Redis subscriber on channel: notifications")
		for {
			select {
			case <-ctx.Done():
				return
			default:
			}

			sub := h.redis.Subscribe(ctx, "notifications")
			ch := sub.Channel()
			func() {
				defer sub.Close()
				for {
					select {
					case <-ctx.Done():
						return
					case msg, ok := <-ch:
						if !ok {
							return
						}
						var payload map[string]interface{}
						if err := json.Unmarshal([]byte(msg.Payload), &payload); err != nil {
							continue
						}
						uidRaw, ok := payload["user_id"]
						if !ok {
							continue
						}
						var userID uint64
						switch v := uidRaw.(type) {
						case float64:
							userID = uint64(v)
						case uint64:
							userID = v
						default:
							continue
						}
						h.SendToUser(userID, map[string]interface{}{
							"type": "notification",
							"data": payload,
						})
					}
				}
			}()

			if ctx.Err() == nil {
				log.Println("[WS-SUB] Reconnecting in 3s...")
				time.Sleep(3 * time.Second)
			}
		}
	}()
}

// StatsHandler is a Gin handler that returns connected client count.
func (h *Hub) StatsHandler() gin.HandlerFunc {
	return func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"connected_clients": h.Count()})
	}
}
