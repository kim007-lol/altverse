<?php

namespace App\Services;

use Illuminate\Support\Facades\Cache;

class CacheService
{
    /**
     * Cache durations in seconds.
     */
    const DURATION_SHORT = 300;      // 5 minutes
    const DURATION_MEDIUM = 1800;    // 30 minutes
    const DURATION_LONG = 3600;      // 1 hour
    const DURATION_DAY = 86400;      // 24 hours

    /**
     * Cache leaderboard data.
     */
    public static function cacheLeaderboard(string $type, int $seasonId, callable $callback, int $duration = self::DURATION_MEDIUM)
    {
        $key = "leaderboard:{$type}:{$seasonId}";
        return Cache::remember($key, $duration, $callback);
    }

    /**
     * Invalidate leaderboard cache.
     */
    public static function invalidateLeaderboard(string $type, int $seasonId): void
    {
        Cache::forget("leaderboard:{$type}:{$seasonId}");
    }

    /**
     * Cache user profile data.
     */
    public static function cacheUserProfile(int $userId, callable $callback, int $duration = self::DURATION_MEDIUM)
    {
        $key = "user:profile:{$userId}";
        return Cache::remember($key, $duration, $callback);
    }

    /**
     * Invalidate user profile cache.
     */
    public static function invalidateUserProfile(int $userId): void
    {
        Cache::forget("user:profile:{$userId}");
    }

    /**
     * Cache series detail.
     */
    public static function cacheSeriesDetail(int $seriesId, callable $callback, int $duration = self::DURATION_LONG)
    {
        $key = "series:detail:{$seriesId}";
        return Cache::remember($key, $duration, $callback);
    }

    /**
     * Invalidate series cache.
     */
    public static function invalidateSeriesDetail(int $seriesId): void
    {
        Cache::forget("series:detail:{$seriesId}");
    }

    /**
     * Cache episode detail.
     */
    public static function cacheEpisodeDetail(int $episodeId, callable $callback, int $duration = self::DURATION_LONG)
    {
        $key = "episode:detail:{$episodeId}";
        return Cache::remember($key, $duration, $callback);
    }

    /**
     * Invalidate episode cache.
     */
    public static function invalidateEpisodeDetail(int $episodeId): void
    {
        Cache::forget("episode:detail:{$episodeId}");
    }

    /**
     * Cache FYP (For You Page) data.
     */
    public static function cacheFYP(int $userId, callable $callback, int $duration = self::DURATION_SHORT)
    {
        $key = "fyp:{$userId}";
        return Cache::remember($key, $duration, $callback);
    }

    /**
     * Invalidate FYP cache.
     */
    public static function invalidateFYP(int $userId): void
    {
        Cache::forget("fyp:{$userId}");
    }

    /**
     * Cache author dashboard.
     */
    public static function cacheAuthorDashboard(int $authorId, callable $callback, int $duration = self::DURATION_SHORT)
    {
        $key = "author:dashboard:{$authorId}";
        return Cache::remember($key, $duration, $callback);
    }

    /**
     * Invalidate author dashboard cache.
     */
    public static function invalidateAuthorDashboard(int $authorId): void
    {
        Cache::forget("author:dashboard:{$authorId}");
    }

    /**
     * Cache trending series.
     */
    public static function cacheTrending(callable $callback, int $duration = self::DURATION_MEDIUM)
    {
        return Cache::remember('trending:series', $duration, $callback);
    }

    /**
     * Invalidate trending cache.
     */
    public static function invalidateTrending(): void
    {
        Cache::forget('trending:series');
    }

    /**
     * Cache popular series.
     */
    public static function cachePopular(callable $callback, int $duration = self::DURATION_LONG)
    {
        return Cache::remember('popular:series', $duration, $callback);
    }

    /**
     * Invalidate popular cache.
     */
    public static function invalidatePopular(): void
    {
        Cache::forget('popular:series');
    }

    /**
     * Bulk invalidate related caches.
     */
    public static function invalidateSeriesRelated(int $seriesId, int $authorId): void
    {
        self::invalidateSeriesDetail($seriesId);
        self::invalidateAuthorDashboard($authorId);
        self::invalidateTrending();
        self::invalidatePopular();
    }

    /**
     * Bulk invalidate user related caches.
     */
    public static function invalidateUserRelated(int $userId): void
    {
        self::invalidateUserProfile($userId);
        self::invalidateFYP($userId);
    }
}
