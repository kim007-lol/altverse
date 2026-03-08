<?php

namespace App\Services;

use App\Models\Badge;
use App\Models\User;

class BadgeService
{
    /**
     * Grant follower-based badges to an author.
     * Call this after a follow/unfollow event.
     */
    public static function grantFollowerBadges(User $user): void
    {
        $followerCount = $user->followers_count;

        $badges = Badge::where('condition_type', 'followers')
            ->where('condition_value', '<=', $followerCount)
            ->get();

        foreach ($badges as $badge) {
            $user->badges()->syncWithoutDetaching([
                $badge->id => ['earned_at' => now()],
            ]);
        }
    }

    /**
     * Get the highest follower badge for an author.
     */
    public static function getHighestFollowerBadge(User $user): ?Badge
    {
        return Badge::where('condition_type', 'followers')
            ->where('condition_value', '<=', $user->followers_count)
            ->orderByDesc('condition_value')
            ->first();
    }
}
