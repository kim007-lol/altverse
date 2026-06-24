package worker

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"image"
	"image/jpeg"
	"image/png"
	"io"
	"log"
	"time"

	"aureader-services/internal/storage"

	"golang.org/x/image/draw"
)

// ImageJob represents an image processing job from Redis.
type ImageJob struct {
	PageID    int64  `json:"page_id"`
	Path      string `json:"path"`      // R2 key (e.g., "episodes/pages/abc_img.png")
	EpisodeID int64  `json:"episode_id"`
	Action    string `json:"action"`    // "optimize"
}

// ImageProcessor listens for image processing jobs from Redis
// and optimizes uploaded images (resize + compress).
type ImageProcessor struct {
	redis    *storage.RedisClient
	r2       *storage.R2Client
	postgres *storage.PostgresClient
	maxWidth int
	quality  int
}

// NewImageProcessor creates a new image processor.
func NewImageProcessor(
	redis *storage.RedisClient,
	r2 *storage.R2Client,
	pg *storage.PostgresClient,
) *ImageProcessor {
	return &ImageProcessor{
		redis:    redis,
		r2:       r2,
		postgres: pg,
		maxWidth: 1200, // Max width in pixels — comics/webtoons don't need > 1200px
		quality:  85,   // JPEG quality (85% is barely noticeable vs 100%)
	}
}

// Start begins the image processor in a goroutine.
// It subscribes to the Redis "image:process" channel.
func (p *ImageProcessor) Start(ctx context.Context) {
	go func() {
		log.Println("[IMG-WORKER] Starting image processor subscriber")

		for {
			select {
			case <-ctx.Done():
				log.Println("[IMG-WORKER] Shutting down...")
				return
			default:
			}

			err := p.redis.Subscribe(ctx, "image:process", func(payload string) {
				var job ImageJob
				if err := json.Unmarshal([]byte(payload), &job); err != nil {
					log.Printf("[IMG-WORKER] Malformed job: %v", err)
					return
				}

				if job.Action != "optimize" || job.Path == "" {
					return
				}

				log.Printf("[IMG-WORKER] 🔧 Processing: page=%d path=%s", job.PageID, job.Path)

				if err := p.processImage(ctx, job); err != nil {
					log.Printf("[IMG-WORKER] ❌ Failed to process page %d: %v", job.PageID, err)
				} else {
					log.Printf("[IMG-WORKER] ✅ Optimized page %d", job.PageID)
				}
			})

			if err != nil && ctx.Err() == nil {
				log.Printf("[IMG-WORKER] Subscriber error: %v — reconnecting in 3s", err)
				time.Sleep(3 * time.Second)
			}
		}
	}()
}

// processImage downloads, optimizes, and re-uploads an image.
func (p *ImageProcessor) processImage(ctx context.Context, job ImageJob) error {
	start := time.Now()

	// 1. Download from R2
	obj, err := p.r2.GetObject(ctx, job.Path)
	if err != nil {
		return fmt.Errorf("download: %w", err)
	}
	defer obj.Body.Close()

	originalSize := obj.Size

	// 2. Decode the image
	rawData, err := io.ReadAll(obj.Body)
	if err != nil {
		return fmt.Errorf("read body: %w", err)
	}

	img, format, err := image.Decode(bytes.NewReader(rawData))
	if err != nil {
		// Not a valid image (could be corrupted), skip
		log.Printf("[IMG-WORKER] Skipping non-image file: %s (format error: %v)", job.Path, err)
		return nil
	}

	bounds := img.Bounds()
	origWidth := bounds.Dx()
	origHeight := bounds.Dy()

	// 3. Resize if wider than maxWidth
	var processed image.Image = img
	newWidth := origWidth
	newHeight := origHeight

	if origWidth > p.maxWidth {
		ratio := float64(p.maxWidth) / float64(origWidth)
		newWidth = p.maxWidth
		newHeight = int(float64(origHeight) * ratio)

		dst := image.NewRGBA(image.Rect(0, 0, newWidth, newHeight))
		draw.CatmullRom.Scale(dst, dst.Bounds(), img, img.Bounds(), draw.Over, nil)
		processed = dst

		log.Printf("[IMG-WORKER] Resized %dx%d → %dx%d", origWidth, origHeight, newWidth, newHeight)
	}

	// 4. Encode as optimized JPEG (best balance of quality + size for comics)
	var buf bytes.Buffer
	outputFormat := "jpeg"
	contentType := "image/jpeg"

	if format == "png" && hasTransparency(img) {
		// Keep PNG if it has transparency
		err = png.Encode(&buf, processed)
		outputFormat = "png"
		contentType = "image/png"
	} else {
		err = jpeg.Encode(&buf, processed, &jpeg.Options{Quality: p.quality})
	}

	if err != nil {
		return fmt.Errorf("encode %s: %w", outputFormat, err)
	}

	newSize := int64(buf.Len())

	// 5. Only re-upload if we actually saved space (> 10% reduction)
	savedPct := float64(originalSize-newSize) / float64(originalSize) * 100
	if savedPct < 10 {
		log.Printf("[IMG-WORKER] Skip re-upload for page %d: only %.1f%% reduction (%d → %d bytes)",
			job.PageID, savedPct, originalSize, newSize)
		return nil
	}

	// 6. Build the optimized path — keep same path to avoid breaking URLs
	reader := bytes.NewReader(buf.Bytes())
	if err := p.r2.PutObject(ctx, job.Path, reader, contentType); err != nil {
		return fmt.Errorf("upload: %w", err)
	}

	// 7. Update page metadata in DB
	_, err = p.postgres.Exec(ctx,
		`UPDATE pages SET width = $1, height = $2, file_size = $3, updated_at = NOW() WHERE id = $4`,
		newWidth, newHeight, newSize, job.PageID,
	)
	if err != nil {
		log.Printf("[IMG-WORKER] ⚠️  DB update failed for page %d: %v", job.PageID, err)
	}

	elapsed := time.Since(start)
	log.Printf("[IMG-WORKER] 📊 Page %d: %s %dx%d → %s %dx%d | %d KB → %d KB (%.0f%% saved) | %s",
		job.PageID, format, origWidth, origHeight,
		outputFormat, newWidth, newHeight,
		originalSize/1024, newSize/1024,
		savedPct, elapsed.Round(time.Millisecond))

	return nil
}

// hasTransparency checks if an image has any transparent pixels.
func hasTransparency(img image.Image) bool {
	bounds := img.Bounds()
	// Sample a subset of pixels for performance
	step := max(1, bounds.Dx()/50)
	for y := bounds.Min.Y; y < bounds.Max.Y; y += step {
		for x := bounds.Min.X; x < bounds.Max.X; x += step {
			_, _, _, a := img.At(x, y).RGBA()
			if a < 0xFFFF {
				return true
			}
		}
	}
	return false
}
