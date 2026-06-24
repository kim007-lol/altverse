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
        $range = $request->input('range', '7d');
        $days  = $this->parseDays($range);

        // Support custom date range
        $startDate = $request->input('start_date');
        $endDate = $request->input('end_date');

        if ($startDate && $endDate) {
            $from = $startDate;
            $to = $endDate;
            $cacheKey = "analytics:overview:{$user->id}:{$from}:{$to}";
        } else {
            $from = now()->subDays($days)->toDateString();
            $to = now()->toDateString();
            $cacheKey = "analytics:overview:{$user->id}:{$range}";
        }

        $data = Cache::remember($cacheKey, 120, function () use ($user, $from, $to) {
            $seriesIds = $user->series()->pluck('id');

            $totalViews = ViewLog::whereIn('series_id', $seriesIds)
                ->whereBetween('viewed_date', [$from, $to])
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

            // Calculate retention (users who viewed multiple episodes)
            $uniqueViewers = ViewLog::whereIn('series_id', $seriesIds)
                ->whereBetween('viewed_date', [$from, $to])
                ->distinct('user_id')
                ->count('user_id');

            $returningViewers = ViewLog::whereIn('series_id', $seriesIds)
                ->whereBetween('viewed_date', [$from, $to])
                ->select('user_id')
                ->groupBy('user_id')
                ->havingRaw('COUNT(*) > 1')
                ->get()
                ->count();

            $retentionRate = $uniqueViewers > 0
                ? round(($returningViewers / $uniqueViewers) * 100, 1)
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
                    'required' => ['followers' => 100, 'total_views' => 100],
                    'current'  => ['followers' => $followers, 'total_views' => $allTimeViews],
                    'met'      => $followers >= 100 && $allTimeViews >= 100,
                ],
                'gold' => [
                    'required' => ['followers' => 500, 'total_views' => 1000],
                    'current'  => ['followers' => $followers, 'total_views' => $allTimeViews],
                    'met'      => $followers >= 500 && $allTimeViews >= 1000,
                ],
                'diamond' => [
                    'required' => ['followers' => 2000, 'total_views' => 5000],
                    'current'  => ['followers' => $followers, 'total_views' => $allTimeViews],
                    'met'      => $followers >= 2000 && $allTimeViews >= 5000,
                ],
                'popular' => [
                    'required' => ['followers' => 7000, 'total_views' => 10000],
                    'current'  => ['followers' => $followers, 'total_views' => $allTimeViews],
                    'met'      => $followers >= 7000 && $allTimeViews >= 10000,
                ],
            ];

            return [
                'total_views'     => $totalViews,
                'total_likes'     => $totalLikes,
                'followers'       => $followers,
                'total_series'    => $seriesIds->count(),
                'total_episodes'  => $totalEpisodes,
                'engagement_rate' => $engagement,
                'unique_viewers'  => $uniqueViewers,
                'returning_viewers' => $returningViewers,
                'retention_rate'  => $retentionRate,
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
        $range = $request->input('range', '7d');
        $days  = $this->parseDays($range);

        // Support custom date range
        $startDate = $request->input('start_date');
        $endDate = $request->input('end_date');

        if ($startDate && $endDate) {
            $from = $startDate;
            $to = $endDate;
            $daysDiff = \Carbon\Carbon::parse($from)->diffInDays(\Carbon\Carbon::parse($to)) + 1;
            $cacheKey = "analytics:trend:{$user->id}:{$from}:{$to}";
        } else {
            $from = now()->subDays($days)->toDateString();
            $to = now()->toDateString();
            $daysDiff = $days;
            $cacheKey = "analytics:trend:{$user->id}:{$range}";
        }

        $data = Cache::remember($cacheKey, 120, function () use ($user, $from, $to, $daysDiff) {
            $seriesIds = $user->series()->pluck('id');

            $viewsRaw = ViewLog::whereIn('series_id', $seriesIds)
                ->whereBetween('viewed_date', [$from, $to])
                ->selectRaw('DATE(viewed_date) as date, COUNT(*) as views')
                ->groupByRaw('DATE(viewed_date)')
                ->orderByRaw('DATE(viewed_date)')
                ->get()
                ->keyBy('date');

            // Fill in missing dates with 0
            $labels = [];
            $views  = [];
            $startCarbon = \Carbon\Carbon::parse($from);

            for ($i = 0; $i < $daysDiff; $i++) {
                $date = $startCarbon->copy()->addDays($i)->toDateString();
                $labels[] = $date;
                $views[]  = isset($viewsRaw[$date]) ? (int) $viewsRaw[$date]->views : 0;
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
                ->limit(3)
                ->get();
        });

        return response()->json($data);
    }

    // ─── 4. Top Episodes ───
    public function topEpisodes(Request $request): JsonResponse
    {
        $user     = $request->user();
        $seriesId = $request->input('series_id');

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
                ->limit(3)
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

    // ─── 5. Export Analytics to CSV ───
    public function export(Request $request)
    {
        $user = $request->user();
        $type = $request->input('type', 'overview'); // overview, series, episodes
        $range = $request->input('range', '30d');
        $days = $this->parseDays($range);
        $from = now()->subDays($days)->toDateString();
        $to = now()->toDateString();

        // Support custom date range
        if ($request->has('start_date') && $request->has('end_date')) {
            $from = $request->input('start_date');
            $to = $request->input('end_date');
        }

        $filename = "analytics_{$type}_" . now()->format('Y-m-d') . ".csv";

        $headers = [
            'Content-Type' => 'text/csv',
            'Content-Disposition' => "attachment; filename=\"{$filename}\"",
        ];

        $callback = function () use ($user, $type, $from, $to) {
            $file = fopen('php://output', 'w');

            if ($type === 'overview') {
                $this->exportOverview($file, $user, $from, $to);
            } elseif ($type === 'series') {
                $this->exportSeries($file, $user);
            } elseif ($type === 'episodes') {
                $this->exportEpisodes($file, $user);
            } elseif ($type === 'trend') {
                $this->exportTrend($file, $user, $from, $to);
            }

            fclose($file);
        };

        return response()->stream($callback, 200, $headers);
    }

    private function exportOverview($file, $user, $from, $to): void
    {
        fputcsv($file, ['Metric', 'Value']);

        $seriesIds = $user->series()->pluck('id');
        $totalViews = ViewLog::whereIn('series_id', $seriesIds)
            ->whereBetween('viewed_date', [$from, $to])
            ->count();
        $totalLikes = $user->series()->sum('total_likes');
        $followers = $user->followers_count ?: $user->followers()->count();
        $totalSeries = $seriesIds->count();
        $totalEpisodes = $user->series()->withCount('episodes')->get()->sum('episodes_count');

        fputcsv($file, ['Period', "{$from} to {$to}"]);
        fputcsv($file, ['Total Views', $totalViews]);
        fputcsv($file, ['Total Likes', $totalLikes]);
        fputcsv($file, ['Followers', $followers]);
        fputcsv($file, ['Total Series', $totalSeries]);
        fputcsv($file, ['Total Episodes', $totalEpisodes]);
        fputcsv($file, ['Author Tier', $user->author_tier]);
    }

    private function exportSeries($file, $user): void
    {
        fputcsv($file, ['Series ID', 'Title', 'Status', 'Total Views', 'Total Likes', 'Episodes Count']);

        $series = $user->series()
            ->withCount('episodes')
            ->orderByDesc('total_views')
            ->get();

        foreach ($series as $s) {
            fputcsv($file, [
                $s->id,
                $s->title,
                $s->status,
                $s->total_views,
                $s->total_likes,
                $s->episodes_count,
            ]);
        }
    }

    private function exportEpisodes($file, $user): void
    {
        fputcsv($file, ['Episode ID', 'Series', 'Episode Title', 'Episode Number', 'View Count', 'Status']);

        $seriesIds = $user->series()->pluck('id');
        $episodes = DB::table('episodes')
            ->whereIn('series_id', $seriesIds)
            ->join('series', 'series.id', '=', 'episodes.series_id')
            ->select(
                'episodes.id',
                'series.title as series_title',
                'episodes.title as episode_title',
                'episodes.episode_number',
                'episodes.view_count',
                'episodes.status'
            )
            ->orderByDesc('episodes.view_count')
            ->get();

        foreach ($episodes as $ep) {
            fputcsv($file, [
                $ep->id,
                $ep->series_title,
                $ep->episode_title,
                $ep->episode_number,
                $ep->view_count,
                $ep->status,
            ]);
        }
    }

    private function exportTrend($file, $user, $from, $to): void
    {
        fputcsv($file, ['Date', 'Views']);

        $seriesIds = $user->series()->pluck('id');
        $viewsRaw = ViewLog::whereIn('series_id', $seriesIds)
            ->whereBetween('viewed_date', [$from, $to])
            ->selectRaw('DATE(viewed_date) as date, COUNT(*) as views')
            ->groupByRaw('DATE(viewed_date)')
            ->orderByRaw('DATE(viewed_date)')
            ->get()
            ->keyBy('date');

        $startCarbon = \Carbon\Carbon::parse($from);
        $endCarbon = \Carbon\Carbon::parse($to);
        $daysDiff = $startCarbon->diffInDays($endCarbon) + 1;

        for ($i = 0; $i < $daysDiff; $i++) {
            $date = $startCarbon->copy()->addDays($i)->toDateString();
            $views = isset($viewsRaw[$date]) ? (int) $viewsRaw[$date]->views : 0;
            fputcsv($file, [$date, $views]);
        }
    }

    // ─── 6. Engagement Metrics ───
    public function engagement(Request $request): JsonResponse
    {
        $user = $request->user();
        $range = $request->input('range', '30d');
        $days = $this->parseDays($range);
        $from = now()->subDays($days)->toDateString();
        $to = now()->toDateString();

        $cacheKey = "analytics:engagement:{$user->id}:{$range}";

        $data = Cache::remember($cacheKey, 120, function () use ($user, $from, $to) {
            $seriesIds = $user->series()->pluck('id');

            // Total interactions
            $totalViews = ViewLog::whereIn('series_id', $seriesIds)
                ->whereBetween('viewed_date', [$from, $to])
                ->count();

            $totalLikes = DB::table('likes')
                ->whereIn('series_id', $seriesIds)
                ->whereBetween('created_at', [$from, $to])
                ->count();

            $totalComments = DB::table('comments')
                ->join('episodes', 'episodes.id', '=', 'comments.episode_id')
                ->whereIn('episodes.series_id', $seriesIds)
                ->whereBetween('comments.created_at', [$from, $to])
                ->count();

            $totalBookmarks = DB::table('bookmarks')
                ->whereIn('series_id', $seriesIds)
                ->whereBetween('created_at', [$from, $to])
                ->count();

            // Engagement rate
            $totalInteractions = $totalLikes + $totalComments + $totalBookmarks;
            $engagementRate = $totalViews > 0
                ? round(($totalInteractions / $totalViews) * 100, 2)
                : 0;

            return [
                'total_views' => $totalViews,
                'total_likes' => $totalLikes,
                'total_comments' => $totalComments,
                'total_bookmarks' => $totalBookmarks,
                'total_interactions' => $totalInteractions,
                'engagement_rate' => $engagementRate,
                'avg_interactions_per_view' => $totalViews > 0
                    ? round($totalInteractions / $totalViews, 2)
                    : 0,
            ];
        });

        return response()->json($data);
    }
}
