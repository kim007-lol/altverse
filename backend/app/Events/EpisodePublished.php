<?php

namespace App\Events;

use App\Models\Episode;
use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class EpisodePublished implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public function __construct(
        public Episode $episode
    ) {}

    public function broadcastOn(): array
    {
        return [
            new Channel('series.' . $this->episode->series_id),
        ];
    }

    public function broadcastWith(): array
    {
        return [
            'episode_id'     => $this->episode->id,
            'title'          => $this->episode->title,
            'episode_number' => $this->episode->episode_number,
            'series_id'      => $this->episode->series_id,
            'published_at'   => $this->episode->published_at,
        ];
    }
}
