<?php

namespace App\Console\Commands;

use App\Jobs\RecalculateAuthorTierJob;
use App\Models\User;
use Illuminate\Console\Command;

class RecalculateAuthorTiers extends Command
{
    protected $signature = 'authors:recalculate-tiers';
    protected $description = 'Recalculate tier for all authors based on multi-factor criteria';

    public function handle(): int
    {
        $count = 0;

        User::where('role', 'author')
            ->chunkById(100, function ($authors) use (&$count) {
                foreach ($authors as $author) {
                    RecalculateAuthorTierJob::dispatch($author->id);
                    $count++;
                }
            });

        $this->info("Dispatched tier recalculation for {$count} authors.");
        return 0;
    }
}
