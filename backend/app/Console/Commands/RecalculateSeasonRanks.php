<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Models\Season;
use App\Models\UserSeasonGlobal;
use App\Models\UserSeasonAuthor;

class RecalculateSeasonRanks extends Command
{
    protected $signature = 'season:recalculate-ranks';
    protected $description = 'Recalculate global and per-author season rankings based on XP';

    public function handle(): int
    {
        $season = Season::where('is_active', true)->first();
        if (!$season) {
            $this->info('No active season found.');
            return 0;
        }

        // ─── Global Ranks (DB-agnostic) ───
        $globals = UserSeasonGlobal::where('season_id', $season->id)
            ->orderByDesc('xp')
            ->orderBy('updated_at')
            ->get();

        $rank = 1;
        foreach ($globals as $entry) {
            if ($entry->rank !== $rank) {
                $entry->update(['rank' => $rank]);
            }
            $rank++;
        }

        $this->info("Recalculated {$globals->count()} global ranks.");

        // ─── Per-Author Ranks ───
        $authorIds = UserSeasonAuthor::where('season_id', $season->id)
            ->distinct('author_id')
            ->pluck('author_id');

        $authorCount = 0;
        foreach ($authorIds as $authorId) {
            $entries = UserSeasonAuthor::where('season_id', $season->id)
                ->where('author_id', $authorId)
                ->orderByDesc('xp')
                ->orderBy('updated_at')
                ->get();

            $aRank = 1;
            foreach ($entries as $entry) {
                if ($entry->rank !== $aRank) {
                    $entry->update(['rank' => $aRank]);
                }
                $aRank++;
            }
            $authorCount++;
        }

        $this->info("Recalculated ranks for $authorCount authors.");
        return 0;
    }
}
