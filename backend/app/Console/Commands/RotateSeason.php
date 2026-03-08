<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Models\Season;
use App\Models\UserSeasonGlobal;
use App\Models\SeasonSupporter;
use App\Models\SeasonAuthorEarning;
use App\Models\User;
use App\Models\Badge;
use App\Models\Transaction;
use App\Models\Notification;
use Illuminate\Support\Str;

class RotateSeason extends Command
{
    protected $signature = 'season:rotate';
    protected $description = 'Check and rotate to a new 90-day season. Distribute rewards if season ended.';

    /**
     * Reward config for Top XP (Top 5 get coins).
     * Total economy impact: 150 coins per season (50+40+30+20+10).
     */
    protected function xpRewardConfig(int $rank): ?array
    {
        return match ($rank) {
            1 => ['coins' => 50],
            2 => ['coins' => 40],
            3 => ['coins' => 30],
            4 => ['coins' => 20],
            5 => ['coins' => 10],
            default => null,
        };
    }

    public function handle(): int
    {
        $activeSeason = Season::where('is_active', true)->first();

        if (!$activeSeason) {
            Season::create([
                'name' => 'Season 1',
                'start_date' => now(),
                'end_date' => now()->addDays(90),
                'is_active' => true,
            ]);
            $this->info('Created first season.');
            return 0;
        }

        if (!now()->gt($activeSeason->end_date)) {
            $daysLeft = now()->diffInDays($activeSeason->end_date);
            $this->info("Season '{$activeSeason->name}' is still active. {$daysLeft} days remaining.");
            return 0;
        }

        // ─── Season has ended: distribute rewards ───
        $this->info("Season '{$activeSeason->name}' ended. Distributing rewards...");

        // ═══ 1. TOP XP REWARDS (coins for Top 5) ═══
        $this->info('--- Top XP Rewards ---');
        $topXpUsers = UserSeasonGlobal::where('season_id', $activeSeason->id)
            ->orderByDesc('xp')
            ->orderBy('updated_at')
            ->limit(5)
            ->get();

        foreach ($topXpUsers as $index => $entry) {
            $rank = $index + 1;
            $reward = $this->xpRewardConfig($rank);
            if (!$reward) continue;

            $user = User::find($entry->user_id);
            if (!$user) continue;

            // Award coins
            $user->increment('coins', $reward['coins']);

            // Record transaction
            Transaction::create([
                'user_id'     => $user->id,
                'type'        => 'season_reward',
                'amount'      => $reward['coins'],
                'description' => "Top XP #{$rank}: {$activeSeason->name} (+{$reward['coins']} coins)",
            ]);

            // Send notification
            Notification::create([
                'id'      => Str::uuid(),
                'user_id' => $user->id,
                'type'    => 'season_reward',
                'title'   => "Top XP #{$rank} 🏆",
                'body'    => "Selamat! Kamu mendapat {$reward['coins']} coins sebagai Top XP #{$rank} di {$activeSeason->name}!",
                'data'    => [
                    'season_id' => $activeSeason->id,
                    'rank'      => $rank,
                    'coins'     => $reward['coins'],
                    'category'  => 'top_xp',
                ],
            ]);

            $this->info("  Top XP #{$rank}: User #{$user->id} → {$reward['coins']} coins");
        }

        // ═══ 2. TOP SUPPORTER REWARDS (badges for Top 3) ═══
        $this->info('--- Top Supporter Rewards ---');
        $topSupporters = SeasonSupporter::where('season_id', $activeSeason->id)
            ->orderByDesc('total_spent')
            ->limit(3)
            ->get();

        foreach ($topSupporters as $index => $entry) {
            $rank = $index + 1;
            $user = User::find($entry->user_id);
            if (!$user) continue;

            // Update rank in the table for historical record
            $entry->update(['rank' => $rank]);

            // Send notification
            Notification::create([
                'id'      => Str::uuid(),
                'user_id' => $user->id,
                'type'    => 'season_reward',
                'title'   => "Top Supporter #{$rank} 💰",
                'body'    => "Selamat! Kamu adalah Top Supporter #{$rank} di {$activeSeason->name}!",
                'data'    => [
                    'season_id' => $activeSeason->id,
                    'rank'      => $rank,
                    'category'  => 'top_supporter',
                ],
            ]);

            $this->info("  Top Supporter #{$rank}: User #{$user->id} → {$entry->total_spent} coins spent");
        }

        // ═══ 3. TOP AUTHOR REWARDS (badges for Top 3) ═══
        $this->info('--- Top Author Rewards ---');
        $topAuthors = SeasonAuthorEarning::where('season_id', $activeSeason->id)
            ->orderByDesc('total_earned')
            ->limit(3)
            ->get();

        foreach ($topAuthors as $index => $entry) {
            $rank = $index + 1;
            $author = User::find($entry->author_id);
            if (!$author) continue;

            // Update rank in the table for historical record
            $entry->update(['rank' => $rank]);

            // Send notification
            Notification::create([
                'id'      => Str::uuid(),
                'user_id' => $author->id,
                'type'    => 'season_reward',
                'title'   => "Top Author #{$rank} 🎨",
                'body'    => "Selamat! Kamu adalah Top Author #{$rank} di {$activeSeason->name}!",
                'data'    => [
                    'season_id' => $activeSeason->id,
                    'rank'      => $rank,
                    'category'  => 'top_author',
                ],
            ]);

            $this->info("  Top Author #{$rank}: Author #{$author->id} → {$entry->total_earned} coins earned");
        }

        // ─── Deactivate + create new season ───
        $activeSeason->update(['is_active' => false]);

        $newNumber = Season::count() + 1;
        $newSeason = Season::create([
            'name' => "Season $newNumber",
            'start_date' => now(),
            'end_date' => now()->addDays(90),
            'is_active' => true,
        ]);

        $this->info("Season rotated: {$newSeason->name} started.");
        return 0;
    }
}
