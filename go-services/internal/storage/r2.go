package storage

import (
	"context"
	"fmt"
	"io"

	"github.com/aws/aws-sdk-go-v2/aws"
	awsconfig "github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/credentials"
	"github.com/aws/aws-sdk-go-v2/service/s3"

	"aureader-services/internal/config"
)

// R2Client wraps an S3 client configured for Cloudflare R2.
type R2Client struct {
	client *s3.Client
	bucket string
}

// ObjectResult holds the data returned when fetching an object from R2.
type ObjectResult struct {
	Body        io.ReadCloser
	ContentType string
	Size        int64
}

// NewR2Client creates a new R2/S3 client from the given configuration.
func NewR2Client(cfg *config.Config) (*R2Client, error) {
	resolver := aws.EndpointResolverWithOptionsFunc(
		func(service, region string, options ...interface{}) (aws.Endpoint, error) {
			return aws.Endpoint{
				URL: cfg.R2Endpoint,
			}, nil
		},
	)

	awsCfg, err := awsconfig.LoadDefaultConfig(context.Background(),
		awsconfig.WithEndpointResolverWithOptions(resolver),
		awsconfig.WithCredentialsProvider(
			credentials.NewStaticCredentialsProvider(cfg.R2AccessKey, cfg.R2SecretKey, ""),
		),
		awsconfig.WithRegion(cfg.R2Region),
	)
	if err != nil {
		return nil, fmt.Errorf("failed to load AWS config: %w", err)
	}

	client := s3.NewFromConfig(awsCfg, func(o *s3.Options) {
		o.UsePathStyle = true
	})

	return &R2Client{
		client: client,
		bucket: cfg.R2Bucket,
	}, nil
}

// GetObject fetches an object from R2 by its key (path).
func (r *R2Client) GetObject(ctx context.Context, path string) (*ObjectResult, error) {
	output, err := r.client.GetObject(ctx, &s3.GetObjectInput{
		Bucket: aws.String(r.bucket),
		Key:    aws.String(path),
	})
	if err != nil {
		return nil, fmt.Errorf("failed to get object %q: %w", path, err)
	}

	contentType := "application/octet-stream"
	if output.ContentType != nil {
		contentType = *output.ContentType
	}

	var size int64
	if output.ContentLength != nil {
		size = *output.ContentLength
	}

	return &ObjectResult{
		Body:        output.Body,
		ContentType: contentType,
		Size:        size,
	}, nil
}

// PutObject uploads data to R2 at the given key.
func (r *R2Client) PutObject(ctx context.Context, path string, body io.ReadSeeker, contentType string) error {
	_, err := r.client.PutObject(ctx, &s3.PutObjectInput{
		Bucket:      aws.String(r.bucket),
		Key:         aws.String(path),
		Body:        body,
		ContentType: aws.String(contentType),
	})
	if err != nil {
		return fmt.Errorf("failed to put object %q: %w", path, err)
	}
	return nil
}

// DeleteObject removes an object from R2.
func (r *R2Client) DeleteObject(ctx context.Context, path string) error {
	_, err := r.client.DeleteObject(ctx, &s3.DeleteObjectInput{
		Bucket: aws.String(r.bucket),
		Key:    aws.String(path),
	})
	if err != nil {
		return fmt.Errorf("failed to delete object %q: %w", path, err)
	}
	return nil
}
