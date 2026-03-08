<?php

namespace App\Jobs;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;

class DeleteOldImageJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 3;
    public int $backoff = 30;

    public function __construct(
        protected string $imagePath
    ) {}

    public function handle(): void
    {
        try {
            if (Storage::disk('s3')->exists($this->imagePath)) {
                Storage::disk('s3')->delete($this->imagePath);
                Log::info("Deleted old image from R2: {$this->imagePath}");
            }
        } catch (\Exception $e) {
            Log::error("Failed to delete image from R2: {$this->imagePath} — {$e->getMessage()}");
            throw $e; // Re-throw to retry
        }
    }

    public function failed(\Throwable $exception): void
    {
        Log::error("DeleteOldImageJob permanently failed for: {$this->imagePath}");
    }
}
