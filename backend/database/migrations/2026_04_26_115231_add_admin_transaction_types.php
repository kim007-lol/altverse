<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        DB::statement('ALTER TABLE transactions DROP CONSTRAINT IF EXISTS transactions_type_check');
        DB::statement("ALTER TABLE transactions ADD CONSTRAINT transactions_type_check CHECK (type IN ('daily_reward', 'tip_sent', 'tip_received', 'episode_unlock', 'episode_unlock_received', 'purchase', 'admin_grant', 'mission_reward', 'topup', 'withdrawal', 'withdrawal_received', 'withdrawal_refund'))");
    }

    public function down(): void
    {
        DB::statement('ALTER TABLE transactions DROP CONSTRAINT IF EXISTS transactions_type_check');
        DB::statement("ALTER TABLE transactions ADD CONSTRAINT transactions_type_check CHECK (type IN ('daily_reward', 'tip_sent', 'tip_received', 'episode_unlock', 'episode_unlock_received', 'purchase', 'admin_grant', 'mission_reward', 'topup', 'withdrawal'))");
    }
};

