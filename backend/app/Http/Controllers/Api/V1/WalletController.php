<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\SendTipRequest;
use App\Models\Badge;
use App\Models\Notification;
use App\Models\Transaction;
use App\Models\User;
use App\Services\BadgeService;
use App\Services\XpService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class WalletController extends Controller
{
    /** Get wallet overview: balance + recent transactions */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();

        $transactions = $user->transactions()
            ->latest()
            ->paginate(20);

        return response()->json([
            'coins'        => $user->coins,
            'transactions' => $transactions,
        ]);
    }

    /**
     * Claim daily reward.
     * FIX #2: Reduced rate from 10+(streak*5) → 5+(streak*2), max ~19/day
     * FIX #4: Integrated XP award (replaces duplicate DailyLoginController)
     * FIX #9: Removed legacy exp_points/level, uses XpService only
     */
    public function claimDailyReward(Request $request): JsonResponse
    {
        $userId = $request->user()->id;

        return DB::transaction(function () use ($userId) {
            // Lock user row to prevent concurrent claims
            $user = User::lockForUpdate()->find($userId);

            $claimedToday = $user->transactions()
                ->where('type', 'daily_reward')
                ->whereDate('created_at', today())
                ->exists();

            if ($claimedToday) {
                return response()->json(['message' => 'Kamu sudah klaim reward hari ini'], 422);
            }

            $streak = 1;
            $checkDate = today()->subDay();
            while ($user->transactions()->where('type', 'daily_reward')->whereDate('created_at', $checkDate)->exists()) {
                $streak++;
                $checkDate = $checkDate->subDay();
            }

            $rewardXp = $streak * 10;

            // Record XP
            $xpRecord = \App\Models\UserXp::firstOrCreate(
                ['user_id' => $user->id],
                ['total_xp' => 0, 'level' => 0]
            );
            $xpRecord->increment('total_xp', $rewardXp);
            $newLevel = \App\Models\UserXp::calculateLevel($xpRecord->total_xp);
            if ($xpRecord->level !== $newLevel) {
                $xpRecord->update(['level' => $newLevel]);
            }

            // Add season global XP
            $season = \App\Models\Season::active()->first();
            if ($season) {
                \App\Models\UserSeasonGlobal::updateOrCreate(
                    ['user_id' => $user->id, 'season_id' => $season->id],
                    []
                )->increment('xp', $rewardXp);
                Cache::forget("leaderboard:xp:{$season->id}");
            }

            Transaction::create([
                'user_id'     => $user->id,
                'type'        => 'daily_reward',
                'amount'      => 0, // 0 coins
                'description' => "Daily reward hari ke-{$streak} (+{$rewardXp} XP)",
            ]);

            // Award streak badge if user has maintained 7+ day streak
            BadgeService::checkStreakBadge($user, $streak);

            Notification::create([
                'id'      => Str::uuid(),
                'user_id' => $user->id,
                'type'    => 'daily_reward',
                'title'   => 'Reward Harian Diklaim!',
                'body'    => "Kamu mendapat {$rewardXp} XP (streak: {$streak} hari)",
            ]);

            return response()->json([
                'message'      => 'Daily reward berhasil diklaim!',
                'xp_earned'    => $rewardXp,
                'coins_earned' => 0,
                'streak'       => $streak,
                'total_xp'     => $xpRecord->fresh()->total_xp,
                'total_coins'  => $user->fresh()->coins,
            ]);
        });
    }

    /**
     * Send tip to author.
     * FIX #3: Wrapped in DB transaction with lockForUpdate (prevents negative coins)
     * FIX #10: Rate limited to max 20 tips per day per user
     * REFACTOR: Tips no longer award XP — only tracked for leaderboard spending.
     */
    public function sendTip(SendTipRequest $request): JsonResponse
    {
        $validated = $request->validated();

        $user = $request->user();

        // Validate target is actually an author (has a pen_name)
        // Note: we don't check $targetUser->role === 'author' because they might be currently in 'reader' mode.
        $targetUser = User::find($validated['author_id']);
        if (!$targetUser || empty($targetUser->pen_name)) {
            return response()->json(['message' => 'Hanya bisa mengirim tip ke Author'], 422);
        }

        if ($user->id === (int) $validated['author_id']) {
            return response()->json(['message' => 'Tidak bisa tip diri sendiri'], 422);
        }

        // FIX #10: Rate limit — max 20 tips per day
        $tipCount = Transaction::where('user_id', $user->id)
            ->where('type', 'tip_sent')
            ->whereDate('created_at', today())
            ->count();

        if ($tipCount >= 20) {
            return response()->json(['message' => 'Batas maksimum 20 tip per hari tercapai'], 429);
        }

        // FIX #3: Atomic transaction with row lock to prevent race condition
        try {
            $result = DB::transaction(function () use ($user, $validated) {
                // Lock user row to prevent concurrent balance manipulation
                $lockedUser = User::lockForUpdate()->find($user->id);

                if ($lockedUser->coins < $validated['amount']) {
                    throw new \Exception('Koin tidak cukup');
                }

                $lockedUser->decrement('coins', $validated['amount']);

                $author = User::lockForUpdate()->find($validated['author_id']);
                $author->increment('coins', $validated['amount']);

                Transaction::create([
                    'user_id'            => $lockedUser->id,
                    'type'               => 'tip_sent',
                    'amount'             => -$validated['amount'],
                    'description'        => 'Tip ke ' . $author->pen_name,
                    'related_user_id'    => $author->id,
                    'related_series_id'  => $validated['series_id'] ?? null,
                ]);

                Transaction::create([
                    'user_id'            => $author->id,
                    'type'               => 'tip_received',
                    'amount'             => $validated['amount'],
                    'description'        => 'Tip dari ' . ($lockedUser->role === 'author' ? $lockedUser->pen_name : $lockedUser->name),
                    'related_user_id'    => $lockedUser->id,
                    'related_series_id'  => $validated['series_id'] ?? null,
                ]);

                Notification::create([
                    'id'      => Str::uuid(),
                    'user_id' => $author->id,
                    'type'        => 'tip_received',
                    'target_role' => 'author',
                    'title'   => 'Tip Diterima!',
                    'body'    => ($lockedUser->role === 'author' ? $lockedUser->pen_name : $lockedUser->name) . " mengirim tip {$validated['amount']} koin",
                    'data'    => ['sender_id' => $lockedUser->id, 'amount' => $validated['amount']],
                ]);

                return $lockedUser->fresh()->coins;
            });
        } catch (\Exception $e) {
            $message = $e->getMessage() === 'Koin tidak cukup'
                ? 'Koin tidak cukup'
                : 'Gagal mengirim tip. Silakan coba lagi.';
            return response()->json(['message' => $message], 422);
        }

        // Track spending for Top Supporter & Top Author leaderboards (NO XP)
        XpService::trackSeasonSpending($user->id, (int) $validated['author_id'], $validated['amount']);

        // Dispatch badge/mission checks to background job
        \App\Jobs\ProcessGamificationJob::dispatch($user->id, 'spend_coins');

        return response()->json([
            'message'     => 'Tip berhasil dikirim!',
            'amount'      => $validated['amount'],
            'total_coins' => $result,
        ]);
    }

    /** Get user's badges */
    public function badges(Request $request): JsonResponse
    {
        $user = $request->user();

        // Get all earned badge IDs with their pivot data
        $earnedData = $user->badges()
            ->get()
            ->keyBy('id')
            ->map(fn($b) => [
                'earned_at' => $b->pivot->earned_at,
                'is_pinned' => (bool) $b->pivot->is_pinned,
            ]);

        // Get ALL badges (not filtered by role) and merge earned_at info
        $allBadges = Badge::all()->map(function ($badge) use ($earnedData) {
            $data = $earnedData->get($badge->id);
            return [
                'id'          => $badge->id,
                'key'         => $badge->key,
                'name'        => $badge->name,
                'description' => $badge->description,
                'icon'        => $badge->icon_url,
                'icon_url'    => $badge->icon_url,
                'category'    => $badge->category,
                'color'       => $badge->color,
                'earned_at'   => $data ? $data['earned_at'] : null,
                'is_pinned'   => $data ? $data['is_pinned'] : false,
            ];
        });

        return response()->json([
            'badges' => $allBadges->values(),
        ]);
    }

    /** Get daily reward status */
    public function dailyStatus(Request $request): JsonResponse
    {
        $user = $request->user();

        // Batch query: get all daily_reward dates in the past 7 days (single query)
        $rewardDates = $user->transactions()
            ->where('type', 'daily_reward')
            ->whereDate('created_at', '>=', today()->subDays(6))
            ->pluck('created_at')
            ->map(fn($d) => $d->toDateString())
            ->unique()
            ->toArray();

        $claimedToday = in_array(today()->toDateString(), $rewardDates);

        $streak = 0;
        if ($claimedToday) {
            $streak = 1;
            $checkDate = today()->subDay();
        } else {
            $checkDate = today()->subDay();
        }

        // Dynamic streak check since streak can be unbounded
        while (Transaction::where('user_id', $user->id)
            ->where('type', 'daily_reward')
            ->whereDate('created_at', $checkDate)
            ->exists()
        ) {
            $streak++;
            $checkDate = $checkDate->subDay();
        }

        $streakValue = $streak + ($claimedToday ? 0 : 1);
        $nextRewardXp = $streakValue * 10;

        $nextRewardCoins = 0;

        $weekDays = [];
        for ($i = 6; $i >= 0; $i--) {
            $date = today()->subDays($i);
            $weekDays[] = [
                'date'    => $date->toDateString(),
                'day'     => $date->format('D'),
                'claimed' => in_array($date->toDateString(), $rewardDates),
            ];
        }

        return response()->json([
            'streak'                  => $streak,
            'claimed_today'           => $claimedToday,
            'next_reward_xp'          => $nextRewardXp,
            'next_reward_coins'       => $nextRewardCoins,
            'has_received_coin_bonus' => true, // Legacy field, no longer used
            'total_xp'                => $user->xpRecord ? $user->xpRecord->total_xp : 0,
            'coins'                   => $user->coins,
            'week_days'               => $weekDays,
        ]);
    }

    /** Get tier progress details */
    public function tierProgress(Request $request): JsonResponse
    {
        $user = $request->user();

        $tier = $user->author_tier ?? 'bronze';

        $tiers = [
            'silver'  => ['followers' => 100, 'total_views' => 100],
            'gold'    => ['followers' => 500, 'total_views' => 1000],
            'diamond' => ['followers' => 2000, 'total_views' => 5000],
            'popular' => ['followers' => 7000, 'total_views' => 10000],
        ];

        $current = [
            'followers'          => $user->followers_count ?? 0,
            'total_views'        => $user->total_views ?? 0,
            'published_episodes' => $user->published_episode_count ?? 0,
            'has_archived_series' => $user->series()->where('status', 'archived')->exists(),
        ];

        $benefits = [
            'bronze'  => [],
            'silver'  => ['can_customize_banner'],
            'gold'    => ['can_customize_banner', 'can_tip'],
            'diamond' => ['can_customize_banner', 'can_tip'],
            'popular' => ['can_customize_banner', 'can_tip', 'is_verified'],
        ];

        $progress = [];
        foreach ($tiers as $tierName => $requirements) {
            $metCount = 0;
            $totalCount = count($requirements);
            $reqProgress = [];

            foreach ($requirements as $key => $reqValue) {
                $curValue = $current[$key] ?? false;
                if (is_bool($reqValue)) {
                    $met = $curValue === true;
                } else {
                    $met = ($curValue >= $reqValue);
                }
                if ($met) $metCount++;

                $reqProgress[$key] = [
                    'required' => $reqValue,
                    'current'  => $curValue,
                    'met'      => $met,
                ];
            }

            $progress[$tierName] = [
                'requirements'    => $reqProgress,
                'all_met'         => $metCount === $totalCount,
                'met_count'       => $metCount,
                'total_count'     => $totalCount,
            ];
        }

        return response()->json([
            'current_tier'     => $tier,
            'current_benefits' => $benefits[$tier] ?? [],
            'all_benefits'     => $benefits,
            'progress'         => $progress,
            'tier_updated_at'  => $user->tier_updated_at,
        ]);
    }
}
