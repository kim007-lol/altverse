<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        DB::statement('ALTER TABLE transactions DROP CONSTRAINT IF EXISTS transactions_type_check');
        DB::statement("ALTER TABLE transactions ADD CONSTRAINT transactions_type_check CHECK (type IN ('daily_reward', 'tip_sent', 'tip_received', 'episode_unlock', 'episode_unlock_received', 'purchase', 'admin_grant', 'mission_reward', 'topup', 'withdrawal'))");
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        DB::statement('ALTER TABLE transactions DROP CONSTRAINT IF EXISTS transactions_type_check');
        DB::statement("ALTER TABLE transactions ADD CONSTRAINT transactions_type_check CHECK (type IN ('daily_reward', 'tip_sent', 'tip_received', 'episode_unlock', 'episode_unlock_received', 'purchase', 'admin_grant', 'mission_reward'))");
    }
};
