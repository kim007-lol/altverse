<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // ─── Follows (Reader → Author) ───
        Schema::create('follows', function (Blueprint $table) {
            $table->id();
            $table->foreignId('follower_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('following_id')->constrained('users')->cascadeOnDelete();
            $table->timestamps();

            $table->unique(['follower_id', 'following_id']);
            $table->index('following_id');
        });

        // ─── Bookmarks (Reader → Series) ───
        Schema::create('bookmarks', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('series_id')->constrained('series')->cascadeOnDelete();
            $table->timestamps();

            $table->unique(['user_id', 'series_id']);
        });

        // ─── Likes (Reader → Series) ───
        Schema::create('likes', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('series_id')->constrained('series')->cascadeOnDelete();
            $table->timestamps();

            $table->unique(['user_id', 'series_id']);
        });

        // ─── Reading History ───
        Schema::create('reading_histories', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('series_id')->constrained('series')->cascadeOnDelete();
            $table->foreignId('episode_id')->constrained('episodes')->cascadeOnDelete();
            $table->unsignedInteger('last_page')->default(1);
            $table->decimal('progress', 5, 2)->default(0);  // 0.00 – 100.00
            $table->timestamp('read_at')->useCurrent();
            $table->timestamps();

            $table->index(['user_id', 'series_id']);
        });

        // ─── Views Log (per episode, for analytics) ───
        Schema::create('views_log', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->foreignId('episode_id')->constrained('episodes')->cascadeOnDelete();
            $table->foreignId('series_id')->constrained('series')->cascadeOnDelete();
            $table->date('viewed_date');
            $table->timestamps();

            $table->index(['series_id', 'viewed_date']);
            $table->index(['episode_id', 'viewed_date']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('views_log');
        Schema::dropIfExists('reading_histories');
        Schema::dropIfExists('likes');
        Schema::dropIfExists('bookmarks');
        Schema::dropIfExists('follows');
    }
};
