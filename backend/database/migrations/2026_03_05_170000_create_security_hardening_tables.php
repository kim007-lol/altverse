<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // ─── 1. Daily XP tracking (DB-based, replaces Redis-only caps) ───
        Schema::create('daily_xp_logs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->date('date');
            $table->string('activity', 30);  // comment, like_received, daily_login, reading_complete
            $table->unsignedInteger('xp_earned')->default(0);
            $table->unsignedInteger('action_count')->default(0); // berapa kali aktivitas dilakukan
            $table->timestamps();

            $table->unique(['user_id', 'date', 'activity']);
            $table->index(['user_id', 'date']);
        });

        // ─── 2. Track which episodes have been completed (XP awarded once) ───
        Schema::create('episode_xp_claims', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('episode_id')->constrained('episodes')->cascadeOnDelete();
            $table->timestamp('claimed_at');

            $table->unique(['user_id', 'episode_id']);
        });

        // ─── 3. Add xp_awarded + is_active columns to comment_likes ───
        // Track whether XP was already given for this like (prevents toggle exploit)
        // is_active = false means "unliked" but we keep history
        Schema::table('comment_likes', function (Blueprint $table) {
            $table->boolean('xp_awarded')->default(false)->after('comment_id');
            $table->boolean('is_active')->default(true)->after('xp_awarded');
        });
    }

    public function down(): void
    {
        Schema::table('comment_likes', function (Blueprint $table) {
            $table->dropColumn(['xp_awarded', 'is_active']);
        });
        Schema::dropIfExists('episode_xp_claims');
        Schema::dropIfExists('daily_xp_logs');
    }
};
