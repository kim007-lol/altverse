<?php

namespace App\Observers;

use App\Models\Page;
use Illuminate\Support\Facades\Redis;
use Illuminate\Support\Facades\Log;

/**
 * Publishes image processing jobs to Redis when a page is created.
 * The Go image processor worker picks these up and optimizes the images
 * (resize + compress) in the background.
 */
class PageObserver
{
    public function created(Page $page): void
    {
        // Skip if no image path
        if (empty($page->image_path)) {
            return;
        }

        try {
            $payload = json_encode([
                'page_id'    => $page->id,
                'episode_id' => $page->episode_id,
                'path'       => $page->getRawOriginal('image_path'),
                'action'     => 'optimize',
            ]);

            Redis::publish('image:process', $payload);

            Log::debug("[PageObserver] Queued image optimization for page {$page->id}");
        } catch (\Throwable $e) {
            // Silent fail — optimization is "best effort"
            Log::debug('[PageObserver] Redis publish failed: ' . $e->getMessage());
        }
    }
}
