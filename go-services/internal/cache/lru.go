package cache

import (
	"container/list"
	"sync"
)

// CachedImage stores a fetched image's bytes and metadata.
type CachedImage struct {
	Data        []byte
	ContentType string
}

// entry is an internal cache entry linked to its LRU position.
type entry struct {
	key   string
	value *CachedImage
	size  int // size in bytes
}

// LRUCache is a thread-safe, size-bounded LRU cache for image data.
type LRUCache struct {
	mu       sync.RWMutex
	maxBytes int
	curBytes int
	ll       *list.List
	items    map[string]*list.Element
}

// NewLRUCache creates a new LRU cache with a maximum size in megabytes.
func NewLRUCache(maxSizeMB int) *LRUCache {
	return &LRUCache{
		maxBytes: maxSizeMB * 1024 * 1024,
		ll:       list.New(),
		items:    make(map[string]*list.Element),
	}
}

// Get retrieves a cached image by key. Returns nil if not found.
func (c *LRUCache) Get(key string) *CachedImage {
	c.mu.RLock()
	elem, ok := c.items[key]
	c.mu.RUnlock()
	if !ok {
		return nil
	}

	c.mu.Lock()
	c.ll.MoveToFront(elem)
	c.mu.Unlock()

	return elem.Value.(*entry).value
}

// Put stores an image in the cache. Evicts least-recently-used entries
// if the cache would exceed its maximum size.
func (c *LRUCache) Put(key string, img *CachedImage) {
	imgSize := len(img.Data)

	// Don't cache images larger than 25% of max cache size
	if imgSize > c.maxBytes/4 {
		return
	}

	c.mu.Lock()
	defer c.mu.Unlock()

	// If key already exists, update it
	if elem, ok := c.items[key]; ok {
		c.ll.MoveToFront(elem)
		old := elem.Value.(*entry)
		c.curBytes -= old.size
		old.value = img
		old.size = imgSize
		c.curBytes += imgSize
		c.evict()
		return
	}

	// Add new entry
	e := &entry{key: key, value: img, size: imgSize}
	elem := c.ll.PushFront(e)
	c.items[key] = elem
	c.curBytes += imgSize
	c.evict()
}

// evict removes least-recently-used entries until we're under the max size.
// Must be called with c.mu held.
func (c *LRUCache) evict() {
	for c.curBytes > c.maxBytes && c.ll.Len() > 0 {
		oldest := c.ll.Back()
		if oldest == nil {
			break
		}
		e := oldest.Value.(*entry)
		c.ll.Remove(oldest)
		delete(c.items, e.key)
		c.curBytes -= e.size
	}
}

// Stats returns current cache statistics.
func (c *LRUCache) Stats() (items int, sizeBytes int, maxBytes int) {
	c.mu.RLock()
	defer c.mu.RUnlock()
	return c.ll.Len(), c.curBytes, c.maxBytes
}
