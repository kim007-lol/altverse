<?php

namespace App\Http\Controllers\Api\V1\Reader;

use App\Http\Controllers\Controller;
use App\Models\Episode;
use App\Models\Transaction;
use App\Services\XpService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class EpisodeUnlockController extends Controller
{
    /** Get list of episodes unlocked by the user */
    public function index(Request $request): JsonResponse
    {
        $unlocked = $request->user()
            ->unlockedEpisodes()
            ->with([
                'series:id,title,slug,cover_url,author_id',
                'series.author:id,name,pen_name'
            ])
            ->select('episodes.id', 'episodes.title', 'episodes.episode_number', 'episodes.series_id', 'episodes.coin_price')
            ->orderByPivot('created_at', 'desc')
            ->paginate(20);

        return response()->json($unlocked);
    }

    /** Unlock a premium episode using coins */
    public function unlock(Request $request, Episode $episode): JsonResponse
    {
        $user    = $request->user();
        $series  = $episode->series;
        $price   = $episode->coin_price;

        // Already free
        if (!$episode->is_premium || $price <= 0) {
            return response()->json(['message' => 'Episode ini gratis'], 422);
        }

        // Already unlocked
        if ($user->unlockedEpisodes()->where('episode_id', $episode->id)->exists()) {
            return response()->json(['message' => 'Episode sudah di-unlock'], 422);
        }

        // Atomic transaction with row lock to prevent race condition (negative coins)
        try {
            $result = DB::transaction(function () use ($user, $episode, $series, $price) {
                // Lock user row to prevent concurrent balance manipulation
                $lockedUser = \App\Models\User::lockForUpdate()->find($user->id);

                if ($lockedUser->coins < $price) {
                    throw new \Exception('Koin tidak cukup');
                }

                $lockedUser->decrement('coins', $price);

                $lockedUser->unlockedEpisodes()->attach($episode->id, [
                    'unlock_type' => 'coin',
                ]);

                Transaction::create([
                    'user_id'           => $lockedUser->id,
                    'type'              => 'episode_unlock',
                    'amount'            => -$price,
                    'description'       => "Unlock: {$series->title} - {$episode->title}",
                    'related_series_id' => $series->id,
                ]);

                // Give coins to author (also lock to prevent race)
                $author = \App\Models\User::lockForUpdate()->find($series->author_id);
                $author->increment('coins', $price);

                Transaction::create([
                    'user_id'           => $author->id,
                    'type'              => 'episode_unlock_received',
                    'amount'            => $price,
                    'description'       => "Episode unlock: {$episode->title}",
                    'related_user_id'   => $lockedUser->id,
                    'related_series_id' => $series->id,
                ]);

                // Notification to author
                $displayName = $lockedUser->role === 'author' ? $lockedUser->pen_name : $lockedUser->name;
                \App\Models\Notification::create([
                    'id'      => Str::uuid(),
                    'user_id' => $author->id,
                    'type'        => 'episode_unlock',
                    'target_role' => 'author',
                    'title'   => 'Episode Unlocked!',
                    'body'    => "{$displayName} membeli {$episode->title}",
                    'data'    => ['buyer_id' => $lockedUser->id, 'amount' => $price],
                ]);

                return $lockedUser->fresh()->coins;
            });
        } catch (\Exception $e) {
            $message = $e->getMessage() === 'Koin tidak cukup'
                ? 'Koin tidak cukup'
                : 'Gagal unlock episode. Silakan coba lagi.';
            return response()->json(['message' => $message], 422);
        }

        // Track season spending for Top Supporter & Top Author leaderboards (NO XP)
        XpService::trackSeasonSpending($user->id, $series->author_id, $price);

        return response()->json([
            'message'     => 'Episode berhasil di-unlock!',
            'coins_spent' => $price,
            'total_coins' => $result,
        ]);
    }
}
