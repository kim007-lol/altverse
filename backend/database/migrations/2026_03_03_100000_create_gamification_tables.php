<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // ─── 1. Supporter Levels (permanent badge tiers) ───
        Schema::create('supporter_levels', function (Blueprint $table) {
            $table->id();
            $table->string('name');              // Bronze, Silver, Gold, Diamond
            $table->unsignedInteger('min_spend'); // minimum lifetime coin spend
            $table->unsignedInteger('weight')->default(0); // priority_score weight
            $table->string('icon')->nullable();
            $table->string('color')->nullable();
            $table->timestamps();

            $table->index('min_spend');
        });

        // ─── 2. Modify users: add gamification fields ───
        Schema::table('users', function (Blueprint $table) {
            $table->unsignedBigInteger('lifetime_spend')->default(0)->after('coins');
            $table->foreignId('supporter_level_id')->nullable()->after('lifetime_spend')
                ->constrained('supporter_levels')->nullOnDelete();
        });

        // ─── 3. User XP (permanent lifetime progression) ───
        Schema::create('user_xp', function (Blueprint $table) {
            $table->foreignId('user_id')->primary()->constrained('users')->cascadeOnDelete();
            $table->unsignedBigInteger('total_xp')->default(0);
            $table->unsignedInteger('level')->default(0);
            $table->timestamps();
        });

        // ─── 4. Seasons (90-day cycles) ───
        Schema::create('seasons', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->date('start_date');
            $table->date('end_date');
            $table->boolean('is_active')->default(true);
            $table->timestamps();

            $table->index('is_active');
        });

        // ─── 5. User Season Global ranking ───
        Schema::create('user_season_global', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('season_id')->constrained('seasons')->cascadeOnDelete();
            $table->unsignedBigInteger('xp')->default(0);
            $table->unsignedInteger('rank')->default(0);
            $table->timestamps();

            $table->unique(['user_id', 'season_id']);
            $table->index(['season_id', 'xp']);
        });

        // ─── 6. User Season Author ranking (per-author loyalty) ───
        Schema::create('user_season_author', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('author_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('season_id')->constrained('seasons')->cascadeOnDelete();
            $table->unsignedBigInteger('xp')->default(0);
            $table->unsignedInteger('rank')->default(0);
            $table->timestamps();

            $table->unique(['user_id', 'author_id', 'season_id']);
            $table->index(['author_id', 'season_id', 'xp']);
        });

        // ─── 7. Author Support Totals (lifetime per-author spend) ───
        Schema::create('author_support_totals', function (Blueprint $table) {
            $table->id();
            $table->foreignId('author_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->unsignedBigInteger('total_spend')->default(0);
            $table->timestamps();

            $table->unique(['author_id', 'user_id']);
            $table->index(['author_id', 'total_spend']);
        });

        // ─── 8. Modify comments: add priority scoring ───
        Schema::table('comments', function (Blueprint $table) {
            $table->unsignedInteger('likes_count')->default(0)->after('body');
            $table->decimal('priority_score', 10, 2)->default(0)->after('likes_count');

            $table->index(['episode_id', 'priority_score']);
        });
    }

    public function down(): void
    {
        Schema::table('comments', function (Blueprint $table) {
            $table->dropIndex(['episode_id', 'priority_score']);
            $table->dropColumn(['likes_count', 'priority_score']);
        });

        Schema::dropIfExists('author_support_totals');
        Schema::dropIfExists('user_season_author');
        Schema::dropIfExists('user_season_global');
        Schema::dropIfExists('seasons');
        Schema::dropIfExists('user_xp');

        Schema::table('users', function (Blueprint $table) {
            $table->dropForeign(['supporter_level_id']);
            $table->dropColumn(['lifetime_spend', 'supporter_level_id']);
        });

        Schema::dropIfExists('supporter_levels');
    }
};
