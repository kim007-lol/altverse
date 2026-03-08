<?php

namespace App\Jobs;

use App\Models\User;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;

class RecalculateAuthorTierJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 3;
    public int $timeout = 60;

    public function __construct(public int $userId) {}

    public function handle(): void
    {
        $user = User::find($this->userId);
        if (!$user || $user->role !== 'author') return;

        // ─── Aggregate fresh stats ───
        $followersCount = $user->followers()->count();
        $totalViews     = $user->series()->sum('total_views');
        $publishedEps   = DB::table('episodes')
            ->join('series', 'series.id', '=', 'episodes.series_id')
            ->where('series.author_id', $user->id)
            ->where('episodes.status', 'published')
            ->count();
        $hasArchivedSeries = $user->series()->where('status', 'archived')->exists();

        // ─── Update denormalized stats ───
        $user->update([
            'followers_count'          => $followersCount,
            'total_views'              => $totalViews,
            'published_episode_count'  => $publishedEps,
        ]);

        // ─── Determine tier (highest match first) ───
        $oldTier = $user->author_tier;
        $newTier = $this->determineTier($followersCount, $totalViews, $publishedEps, $hasArchivedSeries);

        if ($oldTier !== $newTier) {
            $user->update([
                'author_tier'          => $newTier,
                'tier_updated_at'      => now(),
                'can_customize_banner' => in_array($newTier, ['silver', 'gold', 'popular']),
                'can_tip'              => in_array($newTier, ['gold', 'popular']),
                'is_verified'          => $newTier === 'popular' ? true : $user->is_verified,
            ]);

            // ─── Audit history ───
            DB::table('author_tier_histories')->insert([
                'user_id'    => $user->id,
                'old_tier'   => $oldTier,
                'new_tier'   => $newTier,
                'reason'     => json_encode([
                    'followers'          => $followersCount,
                    'total_views'        => $totalViews,
                    'published_episodes' => $publishedEps,
                    'has_archived_series' => $hasArchivedSeries,
                ]),
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }

        // ─── Invalidate caches ───
        Cache::forget("author:{$user->id}:dashboard");
        Cache::forget("analytics:overview:{$user->id}:7");
        Cache::forget("analytics:overview:{$user->id}:30");
        Cache::forget("analytics:overview:{$user->id}:90");
    }

    private function determineTier(int $followers, int $views, int $episodes, bool $hasArchived): string
    {
        if ($followers >= 10000 && $hasArchived) {
            return 'popular';
        }
        if ($followers >= 1000 && $views >= 50000) {
            return 'gold';
        }
        if ($followers >= 100 && $episodes >= 5) {
            return 'silver';
        }
        return 'bronze';
    }
}
