<?php

namespace App\Console\Commands;

use App\Models\TopUp;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Log;

class ExpirePendingTopUps extends Command
{
    /**
     * The name and signature of the console command.
     */
    protected $signature = 'topup:expire-pending';

    /**
     * The console command description.
     */
    protected $description = 'Expire pending top-up transactions older than 24 hours';

    /**
     * Execute the console command.
     */
    public function handle(): int
    {
        $expiredCount = TopUp::where('status', 'pending')
            ->where('created_at', '<', now()->subHours(24))
            ->update(['status' => 'expired']);

        if ($expiredCount > 0) {
            Log::info("ExpirePendingTopUps: Expired {$expiredCount} pending top-up(s).");
            $this->info("Expired {$expiredCount} pending top-up(s).");
        } else {
            $this->info('No pending top-ups to expire.');
        }

        return self::SUCCESS;
    }
}
