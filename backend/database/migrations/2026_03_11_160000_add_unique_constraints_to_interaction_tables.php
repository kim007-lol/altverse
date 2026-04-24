<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * SECURITY FIX: Add UNIQUE constraints to prevent duplicate entries
 * caused by TOCTOU race conditions on concurrent requests.
 *
 * These constraints are the DATABASE-LEVEL safety net.
 * Even if app-level checks fail under concurrency, the DB will reject duplicates.
 */
return new class extends Migration
{
    public function up(): void
    {
        // ─── Comment Likes: one like per user per comment ───
        if (Schema::hasTable('comment_likes')) {
            Schema::table('comment_likes', function (Blueprint $table) {
                // Use try/catch in case the index already exists
                try {
                    $table->unique(['user_id', 'comment_id'], 'comment_likes_user_comment_unique');
                } catch (\Exception $e) {
                    // Index already exists, skip
                }
            });
        }

        // ─── Episode Likes: one like per user per episode ───
        if (Schema::hasTable('episode_likes')) {
            Schema::table('episode_likes', function (Blueprint $table) {
                try {
                    $table->unique(['user_id', 'episode_id'], 'episode_likes_user_episode_unique');
                } catch (\Exception $e) {
                    // Index already exists, skip
                }
            });
        }

        // ─── Series Likes (pivot table): one like per user per series ───
        if (Schema::hasTable('likes')) {
            Schema::table('likes', function (Blueprint $table) {
                try {
                    $table->unique(['user_id', 'series_id'], 'likes_user_series_unique');
                } catch (\Exception $e) {
                    // Index already exists, skip
                }
            });
        }

        // ─── Bookmarks (pivot table): one bookmark per user per series ───
        if (Schema::hasTable('bookmarks')) {
            Schema::table('bookmarks', function (Blueprint $table) {
                try {
                    $table->unique(['user_id', 'series_id'], 'bookmarks_user_series_unique');
                } catch (\Exception $e) {
                    // Index already exists, skip
                }
            });
        }

        // ─── Follows: one follow per user pair ───
        if (Schema::hasTable('follows')) {
            Schema::table('follows', function (Blueprint $table) {
                try {
                    $table->unique(['follower_id', 'following_id'], 'follows_pair_unique');
                } catch (\Exception $e) {
                    // Index already exists, skip
                }
            });
        }
    }

    public function down(): void
    {
        if (Schema::hasTable('comment_likes')) {
            Schema::table('comment_likes', function (Blueprint $table) {
                $table->dropUnique('comment_likes_user_comment_unique');
            });
        }
        if (Schema::hasTable('episode_likes')) {
            Schema::table('episode_likes', function (Blueprint $table) {
                $table->dropUnique('episode_likes_user_episode_unique');
            });
        }
        if (Schema::hasTable('likes')) {
            Schema::table('likes', function (Blueprint $table) {
                $table->dropUnique('likes_user_series_unique');
            });
        }
        if (Schema::hasTable('bookmarks')) {
            Schema::table('bookmarks', function (Blueprint $table) {
                $table->dropUnique('bookmarks_user_series_unique');
            });
        }
        if (Schema::hasTable('follows')) {
            Schema::table('follows', function (Blueprint $table) {
                $table->dropUnique('follows_pair_unique');
            });
        }
    }
};
