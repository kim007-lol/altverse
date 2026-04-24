<?php

namespace App\Http\Controllers\Api\V1\Reader;

use App\Http\Controllers\Controller;
use App\Models\Series;
use App\Models\Episode;
use App\Models\ReadingHistory;
use App\Models\ViewLog;
use App\Models\EpisodeLike;
use App\Models\EpisodeXpClaim;
use App\Services\XpService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ReadingController extends Controller
{
    /** Get reading history */
    public function history(Request $request): JsonResponse
    {
        $history = $request->user()
            ->readingHistories()
            ->with([
                'series:id,title,slug,cover_url,author_id',
                'series.author:id,name,pen_name',
                'episode:id,title,episode_number',
            ])
            ->latest('read_at')
            ->paginate(20);

        return response()->json($history);
    }

    /** Get episode content (pages) for reading */
    public function readEpisode(Request $request, Series $series, Episode $episode): JsonResponse
    {
        // Verify episode belongs to series
        if ($episode->series_id !== $series->id) {
            return response()->json(['message' => 'Episode tidak ditemukan'], 404);
        }

        $user = $request->user();

        // ── Paywall check ──
        if ($episode->is_premium && !$user->hasEpisodeAccess($episode)) {
            $previewPages = $episode->pages()
                ->orderBy('page_order')
                ->take(2)
                ->get(['id', 'image_path', 'page_order']);

            return response()->json([
                'locked'          => true,
                'episode'         => [
                    'id'             => $episode->id,
                    'title'          => $episode->title,
                    'episode_number' => $episode->episode_number,
                    'is_premium'     => true,
                    'coin_price'     => $episode->coin_price,
                ],
                'series_title'    => $series->title,
                'author_name'     => $series->author->pen_name ?? $series->author->name,
                'preview_pages'   => $previewPages,
                'user_coins'      => $user->coins,
                'prev_episode'    => null,
                'next_episode'    => null,
            ]);
        }

        $episode->load(['pages' => fn($q) => $q->orderBy('page_order')]);

        // Throttle view count: only increment if user hasn't viewed this episode today
        $alreadyViewed = ViewLog::where('user_id', $user->id)
            ->where('episode_id', $episode->id)
            ->whereDate('viewed_date', now()->toDateString())
            ->exists();

        if (!$alreadyViewed) {
            $episode->increment('view_count');
            $series->increment('total_views');
        }

        // Log view (always log for history, but view_count only increments once/day)
        ViewLog::firstOrCreate([
            'user_id'     => $user->id,
            'episode_id'  => $episode->id,
            'series_id'   => $series->id,
            'viewed_date' => now()->toDateString(),
        ]);

        // Update reading history
        ReadingHistory::updateOrCreate(
            [
                'user_id'    => $user->id,
                'series_id'  => $series->id,
                'episode_id' => $episode->id,
            ],
            [
                'read_at'   => now(),
                'last_page' => 1,
            ]
        );

        // Get prev/next episode
        $prevEp = $series->episodes()->where('episode_number', '<', $episode->episode_number)->orderByDesc('episode_number')->first(['id', 'title', 'episode_number']);
        $nextEp = $series->episodes()->where('episode_number', '>', $episode->episode_number)->orderBy('episode_number')->first(['id', 'title', 'episode_number']);

        // Episode like status for current user
        $isLiked = EpisodeLike::where('user_id', $request->user()->id)
            ->where('episode_id', $episode->id)
            ->where('is_active', true)
            ->exists();

        // Compute accurate like count from episode_likes table
        $likeCount = EpisodeLike::where('episode_id', $episode->id)
            ->where('is_active', true)
            ->count();

        // Sync the cached column if it drifted
        if ($episode->like_count !== $likeCount) {
            $episode->update(['like_count' => $likeCount]);
        }

        return response()->json([
            'locked'       => false,
            'episode'      => $episode,
            'is_liked'     => $isLiked,
            'like_count'   => $likeCount,
            'prev_episode' => $prevEp,
            'next_episode' => $nextEp,
        ]);
    }

    /**
     * Update reading progress — awards XP ONCE when episode is completed.
     *
     * Security:
     * - XP only awarded if progress >= 100% AND this episode has NOT been claimed before
     * - Uses `episode_xp_claims` table to prevent repeat farming
     * - Also subject to daily cap (30 XP/day for reading_complete)
     */
    public function updateProgress(Request $request, Series $series, Episode $episode): JsonResponse
    {
        $validated = $request->validate([
            'last_page' => 'required|integer|min:1',
            'progress'  => 'required|numeric|min:0|max:100',
        ]);

        $user = $request->user();

        ReadingHistory::updateOrCreate(
            [
                'user_id'    => $user->id,
                'series_id'  => $series->id,
                'episode_id' => $episode->id,
            ],
            [
                'last_page' => $validated['last_page'],
                'progress'  => $validated['progress'],
                'read_at'   => now(),
            ]
        );

        // Automatic XP claim if progress >= 100
        $xpAwarded = false;
        if ($validated['progress'] >= 100) {
            $xpAwarded = app(\App\Services\MissionService::class)->autoClaimMission($user, 'read_episode');
        }

        return response()->json([
            'message'    => 'Progress tersimpan',
            'xp_awarded' => $xpAwarded,
        ]);
    }

    /** Get Series detail with episodes */
    public function seriesDetail(Request $request, Series $series): JsonResponse
    {
        $user = $request->user();

        $series->load([
            'author:id,name,pen_name,avatar_url,bio,author_tier,followers_count',
            'episodes' => fn($q) => $q
                ->where('status', 'published')
                ->orderBy('episode_number')
                ->select('id', 'series_id', 'title', 'episode_number', 'cover_url', 'view_count', 'is_premium', 'coin_price', 'status', 'published_at', 'created_at'),
        ]);

        // Add user-specific flags
        $seriesData = $series->toArray();
        $seriesData['is_liked'] = $user->likes()->where('series_id', $series->id)->exists();
        $seriesData['is_bookmarked'] = $user->bookmarks()->where('series_id', $series->id)->exists();
        $seriesData['is_following'] = $user->following()->where('following_id', $series->author_id)->exists();

        return response()->json(['series' => $seriesData]);
    }

    /**
     * Toggle like on Series.
     * SECURITY: Uses DB::transaction + lockForUpdate to prevent TOCTOU race condition.
     */
    public function toggleLike(Request $request, Series $series): JsonResponse
    {
        $user = $request->user();

        $result = DB::transaction(function () use ($user, $series) {
            // Lock series row — concurrent requests will queue here
            $lockedSeries = Series::lockForUpdate()->find($series->id);

            $isLiked = $user->likes()->where('series_id', $lockedSeries->id)->exists();

            if ($isLiked) {
                $user->likes()->detach($lockedSeries->id);
                $lockedSeries->total_likes = max(0, $lockedSeries->total_likes - 1);
                $lockedSeries->save();
                return ['liked' => false, 'total_likes' => $lockedSeries->total_likes];
            }

            $user->likes()->attach($lockedSeries->id);
            $lockedSeries->increment('total_likes');
            return ['liked' => true, 'total_likes' => $lockedSeries->fresh()->total_likes];
        });

        return response()->json($result);
    }

    /**
     * Toggle like on an Episode (separate from series like).
     * SECURITY: Uses DB::transaction + lockForUpdate to prevent TOCTOU race condition.
     */
    public function toggleEpisodeLike(Request $request, Series $series, Episode $episode): JsonResponse
    {
        $user = $request->user();

        $result = DB::transaction(function () use ($user, $episode) {
            // Lock episode row — concurrent requests will queue here
            $lockedEpisode = Episode::lockForUpdate()->find($episode->id);

            $existing = EpisodeLike::where('user_id', $user->id)
                ->where('episode_id', $lockedEpisode->id)
                ->lockForUpdate()
                ->first();

            if ($existing && $existing->is_active) {
                $existing->update(['is_active' => false]);
                $lockedEpisode->like_count = max(0, $lockedEpisode->like_count - 1);
                $lockedEpisode->save();
                return ['liked' => false, 'like_count' => $lockedEpisode->like_count];
            }

            if ($existing) {
                $existing->update(['is_active' => true]);
            } else {
                EpisodeLike::create([
                    'user_id'    => $user->id,
                    'episode_id' => $lockedEpisode->id,
                    'is_active'  => true,
                ]);
            }

            $lockedEpisode->increment('like_count');
            return ['liked' => true, 'like_count' => $lockedEpisode->fresh()->like_count];
        });

        return response()->json($result);
    }
}
