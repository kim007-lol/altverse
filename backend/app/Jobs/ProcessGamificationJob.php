<?php

namespace App\Jobs;

use App\Models\User;
use App\Services\BadgeService;
use App\Services\MissionService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;

/**
 * ProcessGamificationJob — runs mission tracking and badge checks in the background.
 *
 * Dispatched from controllers so that the HTTP response is not blocked
 * by potentially slow gamification logic (badge DB queries, notification creation, etc.).
 *
 * When the queue driver is "sync" (default during development), this job
 * still executes immediately — but once a real queue driver (Redis, SQS, database)
 * is configured, it will run asynchronously.
 */
class ProcessGamificationJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 2;

    public function __construct(
        public int $userId,
        public string $activity
    ) {}

    public function handle(MissionService $missionService): void
    {
        $user = User::find($this->userId);
        if (!$user) {
            return;
        }

        try {
            // Track mission progress
            $missionService->autoTrack($user, $this->activity);

            // Check relevant badges based on activity type
            match ($this->activity) {
                'read_episode'  => (function () use ($user) {
                    BadgeService::checkReadingBadges($user);
                    BadgeService::checkFinishAUBadges($user); // Check finish_1_au / finish_10_au
                })(),
                'comment'       => BadgeService::checkFirstCommentBadge($user),
                'follow'        => BadgeService::checkFollowBadges($user),
                'bookmark'      => BadgeService::checkFirstBookmarkBadge($user),
                'spend_coins'   => BadgeService::checkAndAwardBadges($user),
                'like_episode'  => null, // No badge for likes
                default         => null,
            };
        } catch (\Throwable $e) {
            Log::error("ProcessGamificationJob failed for user {$this->userId} / {$this->activity}: " . $e->getMessage());
        }
    }
}
