<?php

namespace App\Jobs;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;
use Intervention\Image\ImageManager;
use Intervention\Image\Drivers\Gd\Driver;

class OptimizeImageJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 3;
    public int $timeout = 120;

    public function __construct(
        protected string $imagePath,
        protected int $maxWidth = 1200,
        protected int $quality = 85
    ) {}

    public function handle(): void
    {
        try {
            if (!Storage::disk('s3')->exists($this->imagePath)) {
                Log::warning("Image not found for optimization: {$this->imagePath}");
                return;
            }

            // Download image from R2/S3
            $imageContent = Storage::disk('s3')->get($this->imagePath);
            
            // Create image manager with GD driver
            $manager = new ImageManager(new Driver());
            $image = $manager->read($imageContent);

            // Get original dimensions
            $originalWidth = $image->width();
            $originalHeight = $image->height();

            // Only optimize if image is larger than max width
            if ($originalWidth > $this->maxWidth) {
                // Resize maintaining aspect ratio
                $image->scale(width: $this->maxWidth);
                
                Log::info("Resized image from {$originalWidth}x{$originalHeight} to {$this->maxWidth}x{$image->height()}: {$this->imagePath}");
            }

            // Encode with quality compression
            $optimized = $image->toWebp($this->quality);

            // Generate optimized path (replace extension with .webp)
            $pathInfo = pathinfo($this->imagePath);
            $optimizedPath = $pathInfo['dirname'] . '/' . $pathInfo['filename'] . '_optimized.webp';

            // Upload optimized image back to R2/S3
            Storage::disk('s3')->put($optimizedPath, $optimized);

            Log::info("Optimized image uploaded: {$optimizedPath}");

            // Optionally delete original if optimization successful
            // Storage::disk('s3')->delete($this->imagePath);

        } catch (\Exception $e) {
            Log::error("Failed to optimize image: {$this->imagePath} — {$e->getMessage()}");
            throw $e; // Re-throw to retry
        }
    }

    public function failed(\Throwable $exception): void
    {
        Log::error("OptimizeImageJob permanently failed for: {$this->imagePath}");
    }
}
