<?php

namespace App\Observers;

use App\Models\Notification;
use Illuminate\Support\Facades\Redis;
use Illuminate\Support\Facades\Log;

/**
 * Publishes notification events to Redis pub/sub so the Go WebSocket
 * server can push them to connected clients in real-time.
 */
class NotificationObserver
{
    public function created(Notification $notification): void
    {
        try {
            $payload = json_encode([
                'id'         => $notification->id,
                'user_id'    => $notification->user_id,
                'type'       => $notification->type,
                'title'      => $notification->title,
                'body'       => $notification->body,
                'data'       => $notification->data,
                'is_read'    => false,
                'created_at' => $notification->created_at?->toISOString(),
            ]);

            Redis::publish('notifications', $payload);
        } catch (\Throwable $e) {
            // Silent fail — real-time push is "best effort"
            Log::debug('[NotificationObserver] Redis publish failed: ' . $e->getMessage());
        }
    }
}
