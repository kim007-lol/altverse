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
            $isOwnEpisode = (int) $series->author_id === (int) $user->id;

            $previewPages = $episode->pages()
                ->orderBy('page_order')
                ->take(2)
                ->get(['id', 'image_path', 'page_order']);

            return response()->json([
                'locked'          => true,
                'is_own_episode'  => $isOwnEpisode,
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
            'episode'      => [
                'id'             => $episode->id,
                'title'          => $episode->title,
                'episode_number' => $episode->episode_number,
                'is_premium'     => $episode->is_premium,
                'coin_price'     => $episode->coin_price,
                'music_path'     => $episode->music_path,
                'music_title'    => $episode->music_title,
                'pages'          => $episode->pages,
            ],
            'is_liked'     => $isLiked,
            'like_count'   => $likeCount,
            'prev_episode' => $prevEp,
            'next_episode' => $nextEp,
        ]);
    }

    /**
     * Update reading progress — tracks mission progress when episode completed.
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

        // Dispatch gamification to background job if episode completed
        if ($validated['progress'] >= 100) {
            XpService::award($user->id, 'reading_complete');
            \App\Jobs\ProcessGamificationJob::dispatch($user->id, 'read_episode');
        }

        return response()->json([
            'message' => 'Progress tersimpan',
        ]);
    }

    /**
     * Get Series detail (metadata only — episodes loaded via separate paginated endpoint).
     */
    public function seriesDetail(Request $request, Series $series): JsonResponse
    {
        $user = $request->user();

        $series->load([
            'author:id,name,pen_name,avatar_url,author_avatar_url,bio,author_tier,followers_count',
        ]);

        // Count published episodes without loading them
        $series->loadCount(['episodes' => fn($q) => $q->where('status', 'published')]);

        $seriesData = $series->toArray();
        $seriesData['is_liked'] = $user->likes()->where('series_id', $series->id)->exists();
        $seriesData['is_bookmarked'] = $user->bookmarks()->where('series_id', $series->id)->exists();
        $seriesData['is_following'] = $user->following()->where('following_id', $series->author_id)->exists();
        $seriesData['user_coins'] = $user->coins;
        $seriesData['episode_count'] = $seriesData['episodes_count'] ?? 0;

        // Remove the auto-loaded episodes_count key (we renamed it)
        unset($seriesData['episodes_count']);

        return response()->json(['series' => $seriesData]);
    }

    /**
     * Paginated episode list for a series.
     * Avoids loading hundreds of episodes in a single JSON payload.
     */
    public function seriesEpisodes(Request $request, Series $series): JsonResponse
    {
        $user = $request->user();

        $episodes = $series->episodes()
            ->where('status', 'published')
            ->orderBy('episode_number')
            ->select('id', 'series_id', 'title', 'episode_number', 'cover_url', 'view_count', 'is_premium', 'coin_price', 'status', 'published_at', 'created_at')
            ->paginate(20);

        // Add per-episode unlock status
        $unlockedIds = $user->unlockedEpisodes()
            ->whereIn('episode_id', $episodes->pluck('id'))
            ->pluck('episode_id')
            ->toArray();

        $episodes->getCollection()->transform(function ($ep) use ($unlockedIds) {
            $ep->is_unlocked = in_array($ep->id, $unlockedIds);
            return $ep;
        });

        return response()->json($episodes);
    }

    /**
     * Toggle like on Series.
     * Uses optimistic approach: atomic increment/decrement without row locking.
     */
    public function toggleLike(Request $request, Series $series): JsonResponse
    {
        $user = $request->user();

        $isLiked = $user->likes()->where('series_id', $series->id)->exists();

        if ($isLiked) {
            $user->likes()->detach($series->id);
            $series->decrement('total_likes');
            // Ensure non-negative
            if ($series->fresh()->total_likes < 0) {
                $series->update(['total_likes' => 0]);
            }
            return response()->json(['liked' => false, 'total_likes' => max(0, $series->fresh()->total_likes)]);
        }

        $user->likes()->syncWithoutDetaching([$series->id]);
        $series->increment('total_likes');

        return response()->json(['liked' => true, 'total_likes' => $series->fresh()->total_likes]);
    }

    /**
     * Toggle like on an Episode (separate from series like).
     * Uses optimistic approach: atomic increment/decrement without row locking.
     */
    public function toggleEpisodeLike(Request $request, Series $series, Episode $episode): JsonResponse
    {
        $user = $request->user();

        $existing = EpisodeLike::where('user_id', $user->id)
            ->where('episode_id', $episode->id)
            ->first();

        if ($existing && $existing->is_active) {
            // Unlike
            $existing->update(['is_active' => false]);
            $episode->decrement('like_count');
            if ($episode->fresh()->like_count < 0) {
                $episode->update(['like_count' => 0]);
            }
            return response()->json(['liked' => false, 'like_count' => max(0, $episode->fresh()->like_count)]);
        }

        // Like (new or re-activate)
        if ($existing) {
            $existing->update(['is_active' => true]);
        } else {
            EpisodeLike::create([
                'user_id'    => $user->id,
                'episode_id' => $episode->id,
                'is_active'  => true,
            ]);
        }

        $episode->increment('like_count');

        // Dispatch gamification to background job
        \App\Jobs\ProcessGamificationJob::dispatch($user->id, 'like_episode');

        return response()->json(['liked' => true, 'like_count' => $episode->fresh()->like_count]);
    }
}
