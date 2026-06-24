package shared

import (
	"context"
	"fmt"
	"io"
	"log"
	"net/http"
	"strconv"
	"strings"

	"aureader/backend/pkg/cache"

	"github.com/aws/aws-sdk-go-v2/aws"
	awsconfig "github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/credentials"
	"github.com/aws/aws-sdk-go-v2/service/s3"
	"github.com/gin-gonic/gin"
)

// ImageProxyController serves images from R2 with LRU cache.
type ImageProxyController struct {
	s3     *s3.Client
	bucket string
	lru    *cache.LRUCache
}

type R2Config struct {
	Endpoint  string
	AccessKey string
	SecretKey string
	Region    string
	Bucket    string
}

func NewImageProxyController(cfg R2Config, cacheSizeMB int) (*ImageProxyController, error) {
	resolver := aws.EndpointResolverWithOptionsFunc(
		func(service, region string, options ...interface{}) (aws.Endpoint, error) {
			return aws.Endpoint{URL: cfg.Endpoint}, nil
		},
	)

	awsCfg, err := awsconfig.LoadDefaultConfig(context.Background(),
		awsconfig.WithEndpointResolverWithOptions(resolver),
		awsconfig.WithCredentialsProvider(
			credentials.NewStaticCredentialsProvider(cfg.AccessKey, cfg.SecretKey, ""),
		),
		awsconfig.WithRegion(cfg.Region),
	)
	if err != nil {
		return nil, fmt.Errorf("failed to load AWS config: %w", err)
	}

	client := s3.NewFromConfig(awsCfg, func(o *s3.Options) { o.UsePathStyle = true })

	return &ImageProxyController{
		s3:     client,
		bucket: cfg.Bucket,
		lru:    cache.NewLRUCache(cacheSizeMB),
	}, nil
}

// Serve handles GET /images/*filepath
func (h *ImageProxyController) Serve(c *gin.Context) {
	path := strings.TrimPrefix(c.Param("filepath"), "/")
	if path == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "path is required"})
		return
	}

	if cached := h.lru.Get(path); cached != nil {
		h.sendImage(c, cached.Data, cached.ContentType, "HIT")
		return
	}

	output, err := h.s3.GetObject(c.Request.Context(), &s3.GetObjectInput{
		Bucket: aws.String(h.bucket),
		Key:    aws.String(path),
	})
	if err != nil {
		errStr := err.Error()
		if strings.Contains(errStr, "NoSuchKey") || strings.Contains(errStr, "404") {
			c.JSON(http.StatusNotFound, gin.H{"error": "image not found"})
		} else {
			log.Printf("[IMAGE] R2 fetch error for %s: %v", path, err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to fetch image"})
		}
		return
	}
	defer output.Body.Close()

	data, err := io.ReadAll(output.Body)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to read image"})
		return
	}

	contentType := "application/octet-stream"
	if output.ContentType != nil {
		contentType = *output.ContentType
	}

	h.lru.Put(path, &cache.CachedImage{Data: data, ContentType: contentType})
	h.sendImage(c, data, contentType, "MISS")
}

// CacheStats returns LRU cache statistics.
func (h *ImageProxyController) CacheStats(c *gin.Context) {
	items, sizeBytes, maxBytes := h.lru.Stats()
	c.JSON(http.StatusOK, gin.H{
		"items":     items,
		"size_mb":   fmt.Sprintf("%.1f", float64(sizeBytes)/1024/1024),
		"max_mb":    fmt.Sprintf("%.1f", float64(maxBytes)/1024/1024),
		"usage_pct": fmt.Sprintf("%.1f%%", float64(sizeBytes)/float64(maxBytes)*100),
	})
}

func (h *ImageProxyController) sendImage(c *gin.Context, data []byte, contentType, cacheStatus string) {
	c.Header("Content-Type", contentType)
	c.Header("Content-Length", strconv.Itoa(len(data)))
	c.Header("Cache-Control", "public, max-age=86400, immutable")
	c.Header("X-Cache", cacheStatus)
	c.Data(http.StatusOK, contentType, data)
}
