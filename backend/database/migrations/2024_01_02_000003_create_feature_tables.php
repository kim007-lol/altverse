<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // ─── Collections / Playlists (Reader) ───
        Schema::create('collections', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->string('name');
            $table->string('description')->nullable();
            $table->boolean('is_public')->default(true);
            $table->timestamps();

            $table->index('user_id');
        });

        Schema::create('collection_series', function (Blueprint $table) {
            $table->foreignId('collection_id')->constrained('collections')->cascadeOnDelete();
            $table->foreignId('series_id')->constrained('series')->cascadeOnDelete();
            $table->unsignedInteger('order')->default(0);
            $table->timestamps();

            $table->primary(['collection_id', 'series_id']);
        });

        // ─── Notifications ───
        Schema::create('notifications', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->string('type');        // new_episode, new_follower, comment_reply, badge_earned, daily_reward
            $table->string('title');
            $table->text('body')->nullable();
            $table->jsonb('data')->nullable();   // { series_id, episode_id, sender_id, ... }
            $table->boolean('is_read')->default(false);
            $table->timestamps();

            $table->index(['user_id', 'is_read']);
        });

        // ─── Transactions (Wallet / Koin) ───
        Schema::create('transactions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->enum('type', ['daily_reward', 'tip_sent', 'tip_received', 'episode_unlock', 'purchase', 'admin_grant']);
            $table->integer('amount');    // positif = masuk, negatif = keluar
            $table->text('description')->nullable();
            $table->foreignId('related_user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->foreignId('related_series_id')->nullable()->constrained('series')->nullOnDelete();
            $table->timestamps();

            $table->index(['user_id', 'created_at']);
        });

        // ─── Badges ───
        Schema::create('badges', function (Blueprint $table) {
            $table->id();
            $table->string('key')->unique();
            $table->string('name');
            $table->text('description');
            $table->string('icon_url')->nullable();
            $table->enum('category', ['reader', 'author'])->default('reader');
            $table->timestamps();
        });

        Schema::create('badge_user', function (Blueprint $table) {
            $table->id();
            $table->foreignId('badge_id')->constrained('badges')->cascadeOnDelete();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->unsignedBigInteger('season_id')->nullable();
            $table->boolean('is_pinned')->default(false);
            $table->timestamp('earned_at')->useCurrent();

            $table->unique(['user_id', 'badge_id', 'season_id']);
        });

        // ─── Comments ───
        Schema::create('comments', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('episode_id')->constrained('episodes')->cascadeOnDelete();
            $table->foreignId('parent_id')->nullable()->constrained('comments')->cascadeOnDelete();
            $table->text('body');
            $table->timestamps();
            $table->softDeletes();

            $table->index(['episode_id', 'created_at']);
        });

        // ─── Reports (Content Moderation) ───
        Schema::create('reports', function (Blueprint $table) {
            $table->id();
            $table->foreignId('reporter_id')->constrained('users')->cascadeOnDelete();
            $table->morphs('reportable'); // reportable_type (series, comment, user), reportable_id
            $table->string('reason');
            $table->text('description')->nullable();
            $table->enum('status', ['pending', 'reviewed', 'resolved', 'dismissed'])->default('pending');
            $table->timestamps();

            $table->index('status');
        });

        // ─── Blocked Users ───
        Schema::create('blocked_users', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('blocked_user_id')->constrained('users')->cascadeOnDelete();
            $table->timestamps();

            $table->unique(['user_id', 'blocked_user_id']);
        });

        // ─── Genre Preferences (for personalized FYP) ───
        Schema::create('genre_preferences', function (Blueprint $table) {
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('genre_id')->constrained('genres')->cascadeOnDelete();
            $table->unsignedInteger('weight')->default(1);
            $table->timestamps();

            $table->primary(['user_id', 'genre_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('genre_preferences');
        Schema::dropIfExists('blocked_users');
        Schema::dropIfExists('reports');
        Schema::dropIfExists('comments');
        Schema::dropIfExists('badge_user');
        Schema::dropIfExists('badges');
        Schema::dropIfExists('transactions');
        Schema::dropIfExists('notifications');
        Schema::dropIfExists('collection_series');
        Schema::dropIfExists('collections');
    }
};
