<?php

namespace App\Services;

use App\Models\Badge;
use App\Models\Notification;
use App\Models\User;
use Illuminate\Support\Str;

class BadgeService
{
    /**
     * Check and award all applicable badges for a user.
     * Call this after significant user actions.
     */
    public static function checkAndAwardBadges(User $user): array
    {
        $newBadges = [];

        // Check follower-based badges (for authors)
        if ($user->role === 'author') {
            $newBadges = array_merge($newBadges, self::checkFollowerBadges($user));
        }

        // Check spend-based badges (for readers)
        if ($user->role === 'reader') {
            $newBadges = array_merge($newBadges, self::checkSpendBadges($user));
        }

        // Send notifications for new badges
        foreach ($newBadges as $badge) {
            self::notifyBadgeEarned($user, $badge);
        }

        return $newBadges;
    }

    /**
     * Check and award follower-based badges.
     * Returns array of newly earned badges.
     */
    private static function checkFollowerBadges(User $user): array
    {
        $followerCount = $user->followers_count ?? $user->followers()->count();
        $newBadges = [];

        $badges = Badge::where('condition_type', 'followers')
            ->where('condition_value', '<=', $followerCount)
            ->get();

        foreach ($badges as $badge) {
            // Check if user already has this badge
            if (!$user->badges()->where('badge_id', $badge->id)->exists()) {
                $user->badges()->attach($badge->id, ['earned_at' => now()]);
                $newBadges[] = $badge;
            }
        }

        return $newBadges;
    }

    /**
     * Check and award spend-based badges.
     * Returns array of newly earned badges.
     */
    private static function checkSpendBadges(User $user): array
    {
        // Calculate total spending from transactions
        $totalSpent = $user->transactions()
            ->whereIn('type', ['tip_sent', 'episode_unlock'])
            ->sum('amount');

        // Make positive (transactions are negative for spending)
        $totalSpent = abs($totalSpent);

        $newBadges = [];

        $badges = Badge::where('condition_type', 'spend')
            ->where('condition_value', '<=', $totalSpent)
            ->get();

        foreach ($badges as $badge) {
            // Check if user already has this badge
            if (!$user->badges()->where('badge_id', $badge->id)->exists()) {
                $user->badges()->attach($badge->id, ['earned_at' => now()]);
                $newBadges[] = $badge;
            }
        }

        return $newBadges;
    }

    /**
     * Award a specific badge to a user by key.
     * Used for manual/event-based badges.
     */
    public static function awardBadge(User $user, string $badgeKey): ?Badge
    {
        $badge = Badge::where('key', $badgeKey)->first();

        if (!$badge) {
            return null;
        }

        // Check if user already has this badge
        if ($user->badges()->where('badge_id', $badge->id)->exists()) {
            return null;
        }

        $user->badges()->attach($badge->id, ['earned_at' => now()]);
        self::notifyBadgeEarned($user, $badge);

        return $badge;
    }

    /**
     * Send notification when a badge is earned.
     */
    private static function notifyBadgeEarned(User $user, Badge $badge): void
    {
        Notification::create([
            'id'          => Str::uuid(),
            'user_id'     => $user->id,
            'type'        => 'badge_earned',
            'target_role' => $user->role,
            'title'       => 'Badge Baru! 🏆',
            'body'        => "Kamu mendapatkan badge \"{$badge->name}\"",
            'data'        => [
                'badge_id'   => $badge->id,
                'badge_key'  => $badge->key,
                'badge_name' => $badge->name,
            ],
        ]);
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

    /**
     * Check if user should get "first_au" badge (for authors).
     */
    public static function checkFirstAuBadge(User $user): void
    {
        if ($user->role !== 'author') {
            return;
        }

        $seriesCount = $user->series()->count();
        if ($seriesCount === 1) {
            self::awardBadge($user, 'first_au');
        }
    }

    /**
     * Check if user should get "first_comment" badge (for readers).
     */
    public static function checkFirstCommentBadge(User $user): void
    {
        $commentCount = $user->comments()->count();
        if ($commentCount === 1) {
            self::awardBadge($user, 'first_comment');
        }
    }

    /**
     * Check if user should get "first_bookmark" badge (for readers).
     */
    public static function checkFirstBookmarkBadge(User $user): void
    {
        $bookmarkCount = $user->bookmarks()->count();
        if ($bookmarkCount === 1) {
            self::awardBadge($user, 'first_bookmark');
        }
    }

    /**
     * Check reading-based badges (read_10_chapters, read_50_chapters, etc).
     */
    public static function checkReadingBadges(User $user): void
    {
        $totalRead = $user->readingHistory()->count();

        $milestones = [
            10  => 'read_10_chapters',
            50  => 'read_50_chapters',
            100 => 'read_100_chapters',
        ];

        foreach ($milestones as $count => $badgeKey) {
            if ($totalRead >= $count) {
                self::awardBadge($user, $badgeKey);
            }
        }
    }

    /**
     * Check follow-based badges (follow_5_authors, follow_20_authors).
     */
    public static function checkFollowBadges(User $user): void
    {
        $followCount = $user->following()->count();

        $milestones = [
            5  => 'follow_5_authors',
            20 => 'follow_20_authors',
        ];

        foreach ($milestones as $count => $badgeKey) {
            if ($followCount >= $count) {
                self::awardBadge($user, $badgeKey);
            }
        }
    }
}
