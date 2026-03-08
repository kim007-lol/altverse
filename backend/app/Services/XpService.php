<?php

namespace App\Services;

use App\Models\UserXp;
use App\Models\UserSeasonGlobal;
use App\Models\SeasonSupporter;
use App\Models\SeasonAuthorEarning;
use App\Models\AuthorSupportTotal;
use App\Models\DailyXpLog;
use App\Models\Season;
use App\Models\SupporterLevel;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Cache;

class XpService
{
    /**
     * XP awards per activity type.
     * PURE ENGAGEMENT ONLY — no coin-related XP.
     */
    protected static array $xpMap = [
        'comment'          => 5,   // 5 XP per comment
        'like_received'    => 2,   // 2 XP per like received on your comment
        'daily_login'      => 5,   // 5 XP per daily login
        'reading_complete' => 3,   // 3 XP per episode read to completion
    ];

    /**
     * Daily XP caps per activity — prevents farming.
     * Tracked in `daily_xp_logs` table (DB-based, survives Redis restart).
     */
    protected static array $dailyCaps = [
        'comment'          => 50,  // 10 comments × 5 XP
        'like_received'    => 40,  // 20 likes × 2 XP
        'daily_login'      => 5,   // once per day
        'reading_complete' => 30,  // 10 episodes × 3 XP
    ];

    /**
     * Award XP to a user for an ENGAGEMENT activity.
     * Uses DB-based daily cap tracking (not Redis-only).
     *
     * @param int    $userId   The user earning XP
     * @param string $activity Key from $xpMap
     * @return bool  True if XP was actually awarded
     */
    public static function award(int $userId, string $activity): bool
    {
        $xpAmount = self::$xpMap[$activity] ?? 0;
        if ($xpAmount <= 0) return false;

        // ─── Atomic: cap check + daily log + XP award in ONE transaction ───
        $awarded = DB::transaction(function () use ($userId, $activity, $xpAmount) {
            // 1. Check & update daily cap (with row lock to prevent race condition)
            if (isset(self::$dailyCaps[$activity])) {
                $dailyLog = DailyXpLog::lockForUpdate()->firstOrCreate(
                    [
                        'user_id'  => $userId,
                        'date'     => now()->toDateString(),
                        'activity' => $activity,
                    ],
                    ['xp_earned' => 0, 'action_count' => 0]
                );

                if ($dailyLog->xp_earned >= self::$dailyCaps[$activity]) {
                    return false; // Cap reached
                }

                // Clamp XP to not exceed cap
                $remaining = self::$dailyCaps[$activity] - $dailyLog->xp_earned;
                $xpAmount = min($xpAmount, $remaining);

                if ($xpAmount <= 0) return false;

                // Increment daily log (inside same transaction)
                $dailyLog->increment('xp_earned', $xpAmount);
                $dailyLog->increment('action_count');
            }

            // 2. Update lifetime XP
            $record = UserXp::lockForUpdate()->firstOrCreate(
                ['user_id' => $userId],
                ['total_xp' => 0, 'level' => 0]
            );
            $record->increment('total_xp', $xpAmount);
            $record->refresh();
            $newLevel = UserXp::calculateLevel($record->total_xp);
            if ($record->level !== $newLevel) {
                $record->update(['level' => $newLevel]);
            }

            // 3. Update season global XP (for Top XP leaderboard)
            $season = Season::active()->first();
            if ($season) {
                UserSeasonGlobal::updateOrCreate(
                    ['user_id' => $userId, 'season_id' => $season->id],
                    []
                )->increment('xp', $xpAmount);
            }

            return true;
        });

        if (!$awarded) return false;

        // Invalidate XP leaderboard cache
        $season = Season::active()->first();
        if ($season) {
            Cache::forget("leaderboard:xp:{$season->id}");
        }

        return true;
    }

    /**
     * Track coin spending for Top Supporter and Top Author leaderboards.
     * This does NOT award XP — purely financial tracking.
     *
     * @param int $readerId   The reader who spent coins
     * @param int $authorId   The author who received coins
     * @param int $coinAmount Amount of coins spent/received
     */
    public static function trackSeasonSpending(int $readerId, int $authorId, int $coinAmount): void
    {
        if ($coinAmount <= 0) return;

        $season = Season::active()->first();

        DB::transaction(function () use ($readerId, $authorId, $coinAmount, $season) {
            // 1. Update lifetime spend + supporter level
            $user = User::find($readerId);
            if (!$user) return;

            $user->increment('lifetime_spend', $coinAmount);
            $user->refresh();

            // Older compatibility for UI that might still rely on supporter_level_id 
            // We keep updating it.
            $level = SupporterLevel::where('min_spend', '<=', $user->lifetime_spend)
                ->orderByDesc('min_spend')
                ->first();

            if ($level && $user->supporter_level_id !== $level->id) {
                $user->update(['supporter_level_id' => $level->id]);
            }

            // ─── NEW: Grant Lifetime Supporter Badge ───
            $badgeKey = null;
            if ($user->lifetime_spend >= 10000) $badgeKey = 'lifetime_legendary';
            elseif ($user->lifetime_spend >= 5000) $badgeKey = 'lifetime_platinum';
            elseif ($user->lifetime_spend >= 2000) $badgeKey = 'lifetime_diamond';
            elseif ($user->lifetime_spend >= 1000) $badgeKey = 'lifetime_emas';
            elseif ($user->lifetime_spend >= 500) $badgeKey = 'lifetime_perak';

            if ($badgeKey) {
                $badge = \App\Models\Badge::where('key', $badgeKey)->first();
                if ($badge) {
                    $userBadge = $user->badges()->where('badge_id', $badge->id)->first();
                    if (!$userBadge) {
                        // Grant the badge
                        $user->badges()->attach($badge->id, ['earned_at' => now(), 'is_pinned' => true]);

                        // Unpin older lifetime badges (keep only highest pinned)
                        $lifetimeBadgeKeys = ['lifetime_perak', 'lifetime_emas', 'lifetime_diamond', 'lifetime_platinum', 'lifetime_legendary'];
                        $lifetimeBadgeIds = \App\Models\Badge::whereIn('key', $lifetimeBadgeKeys)
                            ->where('id', '!=', $badge->id)
                            ->pluck('id')
                            ->toArray();

                        if (!empty($lifetimeBadgeIds)) {
                            $user->badges()->updateExistingPivot($lifetimeBadgeIds, ['is_pinned' => false]);
                        }
                    }
                }
            }

            // 2. Update per-author support total (lifetime)
            AuthorSupportTotal::updateOrCreate(
                ['author_id' => $authorId, 'user_id' => $readerId],
                []
            )->increment('total_spend', $coinAmount);

            // 3. Track season-based supporter spending (for Top Supporter leaderboard)
            if ($season) {
                SeasonSupporter::updateOrCreate(
                    ['user_id' => $readerId, 'season_id' => $season->id],
                    []
                )->increment('total_spent', $coinAmount);

                // 4. Track season-based author earning (for Top Author leaderboard)
                SeasonAuthorEarning::updateOrCreate(
                    ['author_id' => $authorId, 'season_id' => $season->id],
                    []
                )->increment('total_earned', $coinAmount);
            }
        });

        // Invalidate leaderboard caches (with season ID!)
        if ($season) {
            Cache::forget("leaderboard:supporters:{$season->id}");
            Cache::forget("leaderboard:authors:{$season->id}");
        }
        Cache::forget("leaderboard:author:{$authorId}:supporters");
    }
}
