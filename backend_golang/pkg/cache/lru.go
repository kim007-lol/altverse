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

type entry struct {
	key   string
	value *CachedImage
	size  int
}

// LRUCache is a thread-safe, size-bounded LRU cache for image data.
type LRUCache struct {
	mu       sync.RWMutex
	maxBytes int
	curBytes int
	ll       *list.List
	items    map[string]*list.Element
}

func NewLRUCache(maxSizeMB int) *LRUCache {
	return &LRUCache{
		maxBytes: maxSizeMB * 1024 * 1024,
		ll:       list.New(),
		items:    make(map[string]*list.Element),
	}
}

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

func (c *LRUCache) Put(key string, img *CachedImage) {
	imgSize := len(img.Data)
	if imgSize > c.maxBytes/4 { // don't cache images >25% of max
		return
	}
	c.mu.Lock()
	defer c.mu.Unlock()
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
	e := &entry{key: key, value: img, size: imgSize}
	elem := c.ll.PushFront(e)
	c.items[key] = elem
	c.curBytes += imgSize
	c.evict()
}

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

func (c *LRUCache) Stats() (items int, sizeBytes int, maxBytes int) {
	c.mu.RLock()
	defer c.mu.RUnlock()
	return c.ll.Len(), c.curBytes, c.maxBytes
}
