<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Badge;
use App\Models\Notification;
use App\Models\Transaction;
use App\Models\User;
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
        $user = $request->user();

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
        $rewardCoins = 0;

        if ($streak === 7) {
            $hasReceivedCoinBonus = Transaction::where('user_id', $user->id)
                ->where('type', 'daily_coin_bonus')
                ->exists();

            if (!$hasReceivedCoinBonus) {
                $rewardCoins = 10;
            }
        }

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

        // Conditionally grant coins
        if ($rewardCoins > 0) {
            $user->increment('coins', $rewardCoins);
            Transaction::create([
                'user_id'     => $user->id,
                'type'        => 'daily_reward',
                'amount'      => $rewardCoins, // only logging the coin transaction amount
                'description' => "Daily reward hari ke-7 (+10 koin, +70 XP)",
            ]);
        } else {
            Transaction::create([
                'user_id'     => $user->id,
                'type'        => 'daily_reward',
                'amount'      => 0, // 0 coins
                'description' => "Daily reward hari ke-{$streak} (+{$rewardXp} XP)",
            ]);
        }

        Notification::create([
            'id'      => Str::uuid(),
            'user_id' => $user->id,
            'type'    => 'daily_reward',
            'title'   => 'Reward Harian Diklaim!',
            'body'    => $rewardCoins > 0
                ? "Selamat! Streak hari ke-7 memberikan {$rewardCoins} koin & {$rewardXp} XP"
                : "Kamu mendapat {$rewardXp} XP (streak: {$streak} hari)",
        ]);

        return response()->json([
            'message'      => 'Daily reward berhasil diklaim!',
            'xp_earned'    => $rewardXp,
            'coins_earned' => $rewardCoins,
            'streak'       => $streak,
            'total_xp'     => $xpRecord->fresh()->total_xp,
            'total_coins'  => $user->fresh()->coins,
        ]);
    }

    /**
     * Send tip to author.
     * FIX #3: Wrapped in DB transaction with lockForUpdate (prevents negative coins)
     * FIX #10: Rate limited to max 20 tips per day per user
     * REFACTOR: Tips no longer award XP — only tracked for leaderboard spending.
     */
    public function sendTip(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'author_id' => 'required|exists:users,id',
            'amount'    => 'required|integer|min:1|max:10000',
            'series_id' => 'nullable|exists:series,id',
        ]);

        $user = $request->user();

        // Validate target is actually an author
        $targetUser = User::find($validated['author_id']);
        if (!$targetUser || $targetUser->role !== 'author') {
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
                    'description'        => 'Tip ke ' . ($author->role === 'author' ? $author->pen_name : $author->name),
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

        $earnedBadges = $user->badges()->get();
        $allBadges = Badge::where('category', $user->role)->get();

        return response()->json([
            'earned' => $earnedBadges,
            'all'    => $allBadges,
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

        $hasReceivedCoinBonus = Transaction::where('user_id', $user->id)
            ->where('type', 'daily_coin_bonus')
            ->exists();

        $nextRewardCoins = ($streakValue === 7 && !$hasReceivedCoinBonus) ? 10 : 0;

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
            'has_received_coin_bonus' => $hasReceivedCoinBonus,
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
            'silver'  => ['followers' => 100, 'published_episodes' => 5],
            'gold'    => ['followers' => 1000, 'total_views' => 50000],
            'popular' => ['followers' => 10000, 'has_archived_series' => true],
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
