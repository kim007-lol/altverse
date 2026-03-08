<?php

namespace App\Http\Controllers\Api\V1\Author;

use App\Http\Controllers\Controller;
use App\Models\ViewLog;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;

class AnalyticsController extends Controller
{
    // ─── 1. Overview Summary ───
    public function overview(Request $request): JsonResponse
    {
        $user  = $request->user();
        $range = $this->parseDays($request->get('range', '7d'));
        $from  = now()->subDays($range)->toDateString();

        $cacheKey = "analytics:overview:{$user->id}:{$range}";

        $data = Cache::remember($cacheKey, 120, function () use ($user, $from) {
            $seriesIds = $user->series()->pluck('id');

            $totalViews = ViewLog::whereIn('series_id', $seriesIds)
                ->where('viewed_date', '>=', $from)
                ->count();

            $totalLikes    = $user->series()->sum('total_likes');
            $followers     = $user->followers_count ?: $user->followers()->count();
            $allTimeViews  = $user->total_views ?: $user->series()->sum('total_views');
            $publishedEps  = $user->published_episode_count;
            $hasArchived   = $user->series()->where('status', 'archived')->exists();

            $totalEpisodes = $user->series()
                ->withCount('episodes')->get()->sum('episodes_count');

            $engagement = $totalViews > 0
                ? round(($totalLikes / $totalViews) * 100, 1)
                : 0;

            // Tier progress (requirements for each tier)
            $tierProgress = [
                'current_tier' => $user->author_tier,
                'benefits'     => array_filter([
                    $user->can_customize_banner ? 'can_customize_banner' : null,
                    $user->can_tip ? 'can_tip' : null,
                    $user->is_verified ? 'is_verified' : null,
                ]),
                'silver' => [
                    'required' => ['followers' => 100, 'published_episodes' => 5],
                    'current'  => ['followers' => $followers, 'published_episodes' => $publishedEps],
                    'met'      => $followers >= 100 && $publishedEps >= 5,
                ],
                'gold' => [
                    'required' => ['followers' => 1000, 'total_views' => 50000],
                    'current'  => ['followers' => $followers, 'total_views' => $allTimeViews],
                    'met'      => $followers >= 1000 && $allTimeViews >= 50000,
                ],
                'popular' => [
                    'required' => ['followers' => 10000, 'has_archived_series' => true],
                    'current'  => ['followers' => $followers, 'has_archived_series' => $hasArchived],
                    'met'      => $followers >= 10000 && $hasArchived,
                ],
            ];

            return [
                'total_views'     => $totalViews,
                'total_likes'     => $totalLikes,
                'followers'       => $followers,
                'total_series'    => $seriesIds->count(),
                'total_episodes'  => $totalEpisodes,
                'engagement_rate' => $engagement,
                'author_tier'     => $user->author_tier,
                'tier_progress'   => $tierProgress,
            ];
        });

        return response()->json($data);
    }

    // ─── 2. Trend Chart (Views per Day) ───
    public function trend(Request $request): JsonResponse
    {
        $user  = $request->user();
        $range = $this->parseDays($request->get('range', '7d'));
        $from  = now()->subDays($range)->toDateString();

        $cacheKey = "analytics:trend:{$user->id}:{$range}";

        $data = Cache::remember($cacheKey, 120, function () use ($user, $from, $range) {
            $seriesIds = $user->series()->pluck('id');

            $viewsRaw = ViewLog::whereIn('series_id', $seriesIds)
                ->where('viewed_date', '>=', $from)
                ->select(DB::raw('viewed_date as date, COUNT(*) as views'))
                ->groupBy('viewed_date')
                ->orderBy('viewed_date')
                ->get()
                ->keyBy('date');

            // Fill in missing dates with 0
            $labels = [];
            $views  = [];
            for ($i = $range - 1; $i >= 0; $i--) {
                $date = now()->subDays($i)->toDateString();
                $labels[] = $date;
                $views[]  = $viewsRaw->has($date) ? (int) $viewsRaw[$date]->views : 0;
            }

            return [
                'labels' => $labels,
                'views'  => $views,
            ];
        });

        return response()->json($data);
    }

    // ─── 3. Top Series ───
    public function topSeries(Request $request): JsonResponse
    {
        $user = $request->user();

        $cacheKey = "analytics:top_series:{$user->id}";

        $data = Cache::remember($cacheKey, 120, function () use ($user) {
            return $user->series()
                ->select('id', 'title', 'cover_url', 'total_views', 'total_likes', 'status')
                ->withCount('episodes')
                ->orderByDesc('total_views')
                ->limit(10)
                ->get();
        });

        return response()->json($data);
    }

    // ─── 4. Top Episodes ───
    public function topEpisodes(Request $request): JsonResponse
    {
        $user     = $request->user();
        $seriesId = $request->get('series_id');

        $cacheKey = "analytics:top_episodes:{$user->id}:" . ($seriesId ?? 'all');

        $data = Cache::remember($cacheKey, 120, function () use ($user, $seriesId) {
            $seriesIds = $seriesId
                ? [$seriesId]
                : $user->series()->pluck('id')->toArray();

            return DB::table('episodes')
                ->whereIn('series_id', $seriesIds)
                ->join('series', 'series.id', '=', 'episodes.series_id')
                ->select(
                    'episodes.id',
                    'episodes.title as episode_title',
                    'episodes.episode_number',
                    'episodes.view_count',
                    'series.title as series_title',
                    'series.id as series_id'
                )
                ->orderByDesc('episodes.view_count')
                ->limit(10)
                ->get();
        });

        return response()->json($data);
    }

    // ─── Helper: parse "7d" → 7, "30d" → 30 ───
    private function parseDays(string $range): int
    {
        return match ($range) {
            '30d'   => 30,
            '90d'   => 90,
            '365d'  => 365,
            default => 7,
        };
    }
}
