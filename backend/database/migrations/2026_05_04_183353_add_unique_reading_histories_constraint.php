<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        // First, clean up any duplicate rows (keep the latest one per user+series+episode)
        DB::statement("
            DELETE FROM reading_histories
            WHERE id NOT IN (
                SELECT MIN(id)
                FROM reading_histories
                GROUP BY user_id, series_id, episode_id
            )
        ");

        Schema::table('reading_histories', function (Blueprint $table) {
            $table->unique(['user_id', 'series_id', 'episode_id'], 'uq_reading_histories_user_series_episode');
        });

        // Also add a unique constraint for views_log (user+episode+date)
        // so Go's ON CONFLICT DO NOTHING works correctly
        Schema::table('views_log', function (Blueprint $table) {
            $table->unique(['user_id', 'episode_id', 'viewed_date'], 'uq_views_log_user_episode_date');
        });
    }

    public function down(): void
    {
        Schema::table('reading_histories', function (Blueprint $table) {
            $table->dropUnique('uq_reading_histories_user_series_episode');
        });

        Schema::table('views_log', function (Blueprint $table) {
            $table->dropUnique('uq_views_log_user_episode_date');
        });
    }
};
