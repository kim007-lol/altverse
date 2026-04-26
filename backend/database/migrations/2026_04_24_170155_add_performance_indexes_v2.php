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
        // User Missions - frequently queried by user_id + mission_id
        if (Schema::hasTable('user_missions')) {
            Schema::table('user_missions', function (Blueprint $table) {
                $table->index(['user_id', 'mission_id'], 'idx_user_missions_user_mission');
                $table->index(['user_id', 'completed_at'], 'idx_user_missions_user_completed');
            });
        }

        // Transactions - frequently queried by user_id + type + date
        if (Schema::hasTable('transactions')) {
            Schema::table('transactions', function (Blueprint $table) {
                $table->index(['user_id', 'type'], 'idx_transactions_user_type');
                $table->index(['user_id', 'created_at'], 'idx_transactions_user_created');
            });
        }

        // Notifications - frequently queried by user_id + target_role + is_read
        if (Schema::hasTable('notifications')) {
            Schema::table('notifications', function (Blueprint $table) {
                $table->index(['user_id', 'target_role'], 'idx_notifications_user_role');
                $table->index(['user_id', 'is_read'], 'idx_notifications_user_read');
            });
        }

        // Reading Histories - frequently queried by user_id + progress
        if (Schema::hasTable('reading_histories')) {
            Schema::table('reading_histories', function (Blueprint $table) {
                $table->index(['user_id', 'progress'], 'idx_reading_histories_user_progress');
                $table->index(['user_id', 'episode_id'], 'idx_reading_histories_user_episode');
            });
        }

        // Views Log - frequently queried by user_id + episode_id + date
        if (Schema::hasTable('views_log')) {
            Schema::table('views_log', function (Blueprint $table) {
                $table->index(['user_id', 'episode_id', 'viewed_date'], 'idx_views_log_user_episode_date');
            });
        }

        // Episode Likes - frequently queried by user_id + episode_id
        if (Schema::hasTable('episode_likes')) {
            Schema::table('episode_likes', function (Blueprint $table) {
                $table->index(['user_id', 'episode_id', 'is_active'], 'idx_episode_likes_user_episode_active');
            });
        }

        // Comment Likes - frequently queried by user_id + comment_id
        if (Schema::hasTable('comment_likes')) {
            Schema::table('comment_likes', function (Blueprint $table) {
                $table->index(['user_id', 'comment_id', 'is_active'], 'idx_comment_likes_user_comment_active');
                $table->index(['user_id', 'is_active', 'created_at'], 'idx_comment_likes_user_active_date');
            });
        }

        // Comments - frequently queried by user_id + episode_id + date
        if (Schema::hasTable('comments')) {
            Schema::table('comments', function (Blueprint $table) {
                $table->index(['user_id', 'episode_id'], 'idx_comments_user_episode');
                $table->index(['user_id', 'created_at'], 'idx_comments_user_date');
                $table->index(['episode_id', 'parent_id', 'deleted_at'], 'idx_comments_episode_parent_deleted');
            });
        }

        // User Season Global - frequently queried by user_id + season_id
        if (Schema::hasTable('user_season_global')) {
            Schema::table('user_season_global', function (Blueprint $table) {
                $table->index(['user_id', 'season_id'], 'idx_user_season_global_user_season');
                $table->index(['season_id', 'xp'], 'idx_user_season_global_season_xp');
            });
        }

        // User Season Author - frequently queried by user_id + season_id
        if (Schema::hasTable('user_season_author')) {
            Schema::table('user_season_author', function (Blueprint $table) {
                $table->index(['user_id', 'season_id'], 'idx_user_season_author_user_season');
                $table->index(['season_id', 'author_id', 'xp'], 'idx_user_season_author_season_author_xp');
            });
        }

        // Season Supporters - frequently queried by user_id + season_id
        if (Schema::hasTable('season_supporters')) {
            Schema::table('season_supporters', function (Blueprint $table) {
                $table->index(['user_id', 'season_id'], 'idx_season_supporters_user_season');
                $table->index(['season_id', 'total_spent'], 'idx_season_supporters_season_spent');
            });
        }

        // Episodes - frequently queried by series_id + status
        if (Schema::hasTable('episodes')) {
            Schema::table('episodes', function (Blueprint $table) {
                $table->index(['series_id', 'status'], 'idx_episodes_series_status');
                $table->index(['series_id', 'episode_number'], 'idx_episodes_series_number');
                $table->index(['status', 'published_at'], 'idx_episodes_status_published');
            });
        }

        // Series - frequently queried by author_id + status
        if (Schema::hasTable('series')) {
            Schema::table('series', function (Blueprint $table) {
                $table->index(['author_id', 'status'], 'idx_series_author_status');
                $table->index(['status', 'total_views'], 'idx_series_status_views');
                $table->index(['status', 'total_likes'], 'idx_series_status_likes');
            });
        }

        // Pages - frequently queried by episode_id + page_order
        if (Schema::hasTable('pages')) {
            Schema::table('pages', function (Blueprint $table) {
                $table->index(['episode_id', 'page_order'], 'idx_pages_episode_order');
            });
        }

        // Bookmarks - frequently queried by user_id + series_id
        if (Schema::hasTable('bookmarks')) {
            Schema::table('bookmarks', function (Blueprint $table) {
                $table->index(['user_id', 'series_id'], 'idx_bookmarks_user_series');
            });
        }

        // Follows - frequently queried by follower_id + following_id
        if (Schema::hasTable('follows')) {
            Schema::table('follows', function (Blueprint $table) {
                $table->index(['follower_id', 'following_id'], 'idx_follows_follower_following');
                $table->index(['following_id', 'created_at'], 'idx_follows_following_date');
            });
        }

        // User Episode Unlocks - frequently queried by user_id + episode_id
        if (Schema::hasTable('user_episode_unlocks')) {
            Schema::table('user_episode_unlocks', function (Blueprint $table) {
                $table->index(['user_id', 'episode_id'], 'idx_user_episode_unlocks_user_episode');
            });
        }

        // Daily XP Logs - frequently queried by user_id + date
        if (Schema::hasTable('daily_xp_logs')) {
            Schema::table('daily_xp_logs', function (Blueprint $table) {
                $table->index(['user_id', 'date'], 'idx_daily_xp_logs_user_date');
            });
        }

        // Episode XP Claims - frequently queried by user_id + episode_id
        if (Schema::hasTable('episode_xp_claims')) {
            Schema::table('episode_xp_claims', function (Blueprint $table) {
                $table->index(['user_id', 'episode_id'], 'idx_episode_xp_claims_user_episode');
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        if (Schema::hasTable('user_missions')) {
            Schema::table('user_missions', function (Blueprint $table) {
                $table->dropIndex('idx_user_missions_user_mission');
                $table->dropIndex('idx_user_missions_user_completed');
            });
        }

        if (Schema::hasTable('transactions')) {
            Schema::table('transactions', function (Blueprint $table) {
                $table->dropIndex('idx_transactions_user_type');
                $table->dropIndex('idx_transactions_user_created');
            });
        }

        if (Schema::hasTable('notifications')) {
            Schema::table('notifications', function (Blueprint $table) {
                $table->dropIndex('idx_notifications_user_role');
                $table->dropIndex('idx_notifications_user_read');
            });
        }

        if (Schema::hasTable('reading_histories')) {
            Schema::table('reading_histories', function (Blueprint $table) {
                $table->dropIndex('idx_reading_histories_user_progress');
                $table->dropIndex('idx_reading_histories_user_episode');
            });
        }

        if (Schema::hasTable('views_log')) {
            Schema::table('views_log', function (Blueprint $table) {
                $table->dropIndex('idx_views_log_user_episode_date');
            });
        }

        if (Schema::hasTable('episode_likes')) {
            Schema::table('episode_likes', function (Blueprint $table) {
                $table->dropIndex('idx_episode_likes_user_episode_active');
            });
        }

        if (Schema::hasTable('comment_likes')) {
            Schema::table('comment_likes', function (Blueprint $table) {
                $table->dropIndex('idx_comment_likes_user_comment_active');
                $table->dropIndex('idx_comment_likes_user_active_date');
            });
        }

        if (Schema::hasTable('comments')) {
            Schema::table('comments', function (Blueprint $table) {
                $table->dropIndex('idx_comments_user_episode');
                $table->dropIndex('idx_comments_user_date');
                $table->dropIndex('idx_comments_episode_parent_deleted');
            });
        }

        if (Schema::hasTable('user_season_global')) {
            Schema::table('user_season_global', function (Blueprint $table) {
                $table->dropIndex('idx_user_season_global_user_season');
                $table->dropIndex('idx_user_season_global_season_xp');
            });
        }

        if (Schema::hasTable('user_season_author')) {
            Schema::table('user_season_author', function (Blueprint $table) {
                $table->dropIndex('idx_user_season_author_user_season');
                $table->dropIndex('idx_user_season_author_season_author_xp');
            });
        }

        if (Schema::hasTable('season_supporters')) {
            Schema::table('season_supporters', function (Blueprint $table) {
                $table->dropIndex('idx_season_supporters_user_season');
                $table->dropIndex('idx_season_supporters_season_spent');
            });
        }

        if (Schema::hasTable('episodes')) {
            Schema::table('episodes', function (Blueprint $table) {
                $table->dropIndex('idx_episodes_series_status');
                $table->dropIndex('idx_episodes_series_number');
                $table->dropIndex('idx_episodes_status_published');
            });
        }

        if (Schema::hasTable('series')) {
            Schema::table('series', function (Blueprint $table) {
                $table->dropIndex('idx_series_author_status');
                $table->dropIndex('idx_series_status_views');
                $table->dropIndex('idx_series_status_likes');
            });
        }

        if (Schema::hasTable('pages')) {
            Schema::table('pages', function (Blueprint $table) {
                $table->dropIndex('idx_pages_episode_order');
            });
        }

        if (Schema::hasTable('bookmarks')) {
            Schema::table('bookmarks', function (Blueprint $table) {
                $table->dropIndex('idx_bookmarks_user_series');
            });
        }

        if (Schema::hasTable('follows')) {
            Schema::table('follows', function (Blueprint $table) {
                $table->dropIndex('idx_follows_follower_following');
                $table->dropIndex('idx_follows_following_date');
            });
        }

        if (Schema::hasTable('user_episode_unlocks')) {
            Schema::table('user_episode_unlocks', function (Blueprint $table) {
                $table->dropIndex('idx_user_episode_unlocks_user_episode');
            });
        }

        if (Schema::hasTable('daily_xp_logs')) {
            Schema::table('daily_xp_logs', function (Blueprint $table) {
                $table->dropIndex('idx_daily_xp_logs_user_date');
            });
        }

        if (Schema::hasTable('episode_xp_claims')) {
            Schema::table('episode_xp_claims', function (Blueprint $table) {
                $table->dropIndex('idx_episode_xp_claims_user_episode');
            });
        }
    }
};
