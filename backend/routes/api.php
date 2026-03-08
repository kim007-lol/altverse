<?php

use App\Http\Controllers\Api\V1\AuthController;
use App\Http\Controllers\Api\V1\NotificationController;
use App\Http\Controllers\Api\V1\WalletController;
use App\Http\Controllers\Api\V1\CommentController;
use App\Http\Controllers\Api\V1\Reader\FypController;
use App\Http\Controllers\Api\V1\Reader\SearchController;
use App\Http\Controllers\Api\V1\Reader\BookmarkController;
use App\Http\Controllers\Api\V1\Reader\FollowController;
use App\Http\Controllers\Api\V1\Reader\ReadingController;
use App\Http\Controllers\Api\V1\Reader\CollectionController;
use App\Http\Controllers\Api\V1\Reader\EpisodeUnlockController;
use App\Http\Controllers\Api\V1\Reader\ReaderProfileController;
use App\Http\Controllers\Api\V1\LeaderboardController;
use App\Http\Controllers\Api\V1\Gamification\MissionController;
use App\Http\Controllers\Api\V1\Gamification\BadgeController;
use App\Http\Controllers\Api\V1\Author\SeriesController;
use App\Http\Controllers\Api\V1\Author\EpisodeController;
use App\Http\Controllers\Api\V1\Author\PageController;
use App\Http\Controllers\Api\V1\Author\AnalyticsController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| AU Reader V2 — API Routes
|--------------------------------------------------------------------------
*/

// ─── Public Auth ───
Route::prefix('v1/auth')->group(function () {
    Route::post('register', [AuthController::class, 'register']);
    Route::post('login', [AuthController::class, 'login'])->middleware('throttle:5,1');
});

// ─── Authenticated Routes ───
Route::prefix('v1')->middleware('auth:sanctum')->group(function () {

    // ── Auth Management ──
    Route::post('auth/logout', [AuthController::class, 'logout']);
    Route::get('auth/me', [AuthController::class, 'me']);
    Route::match(['put', 'post'], 'auth/profile', [AuthController::class, 'updateProfile']);
    Route::post('auth/switch-role', [AuthController::class, 'switchRole']);

    // ── Notifications (semua role) ──
    Route::prefix('notifications')->group(function () {
        Route::get('/', [NotificationController::class, 'index']);
        Route::get('unread-count', [NotificationController::class, 'unreadCount']);
        Route::post('{id}/read', [NotificationController::class, 'markRead']);
        Route::post('read-all', [NotificationController::class, 'markAllRead']);
    });

    // ── Wallet (info visible to all, earning restricted to readers) ──
    Route::prefix('wallet')->group(function () {
        Route::get('/', [WalletController::class, 'index']);
        Route::get('daily-status', [WalletController::class, 'dailyStatus']);
        Route::post('tip', [WalletController::class, 'sendTip']);
        Route::get('badges', [WalletController::class, 'badges']);
        Route::get('tier-progress', [WalletController::class, 'tierProgress']);

        // Daily reward claim — Reader only
        Route::post('daily-reward', [WalletController::class, 'claimDailyReward'])
            ->middleware('reader-only');
    });

    // ── Missions (Reader only — Authors cannot farm XP) ──
    Route::prefix('missions')->middleware('reader-only')->group(function () {
        Route::get('/', [MissionController::class, 'index']);
        Route::post('{code}/claim', [MissionController::class, 'claim']);
    });

    Route::post('users/badges/{badge}/pin', [BadgeController::class, 'pin']);

    // ── Leaderboard ──
    Route::prefix('leaderboard')->group(function () {
        Route::get('overview', [LeaderboardController::class, 'overview']);
        Route::get('top-xp', [LeaderboardController::class, 'topXp']);
        Route::get('top-supporters', [LeaderboardController::class, 'topSupporters']);
        Route::get('top-authors', [LeaderboardController::class, 'topAuthors']);
        Route::get('author/{author}/supporters', [LeaderboardController::class, 'authorSupporters']);
    });

    // ── Comments (semua role) ──
    Route::get('episodes/{episode}/comments', [CommentController::class, 'index']);
    Route::post('episodes/{episode}/comments', [CommentController::class, 'store']);
    Route::post('comments/{comment}/like', [CommentController::class, 'toggleLike']);
    Route::delete('comments/{comment}', [CommentController::class, 'destroy']);

    // ─── Reader (role-guarded) ───
    Route::prefix('reader')->middleware('reader-only')->group(function () {
        // FYP & Search
        Route::get('fyp', [FypController::class, 'index']);
        Route::get('search', [SearchController::class, 'index']);

        // Profile
        Route::get('profile', [ReaderProfileController::class, 'me']);
        Route::get('profile/{user}', [ReaderProfileController::class, 'show']);

        // Bookmarks
        Route::get('bookmarks', [BookmarkController::class, 'index']);
        Route::post('bookmarks/{series}/toggle', [BookmarkController::class, 'toggle']);
        Route::get('bookmarks/{series}/check', [BookmarkController::class, 'check']);

        // Following
        Route::get('following', [FollowController::class, 'following']);
        Route::get('followers', [FollowController::class, 'followers']);
        Route::post('follow/{user}/toggle', [FollowController::class, 'toggle']);
        Route::get('follow/{user}/check', [FollowController::class, 'check']);
        Route::get('author/{user}/profile', [FollowController::class, 'authorProfile']);

        // Reading
        Route::get('history', [ReadingController::class, 'history']);
        Route::get('series/{series}', [ReadingController::class, 'seriesDetail']);
        Route::get('series/{series}/episodes/{episode}', [ReadingController::class, 'readEpisode']);
        Route::post('series/{series}/episodes/{episode}/progress', [ReadingController::class, 'updateProgress']);
        Route::post('series/{series}/like', [ReadingController::class, 'toggleLike']);
        Route::post('series/{series}/episodes/{episode}/like', [ReadingController::class, 'toggleEpisodeLike']);

        // Episode Unlock (coin-based)
        Route::get('episodes/unlocked', [EpisodeUnlockController::class, 'index']);
        Route::post('episodes/{episode}/unlock', [EpisodeUnlockController::class, 'unlock']);

        // Collections
        Route::get('collections', [CollectionController::class, 'index']);
        Route::post('collections', [CollectionController::class, 'store']);
        Route::get('collections/{collection}', [CollectionController::class, 'show']);
        Route::put('collections/{collection}', [CollectionController::class, 'update']);
        Route::delete('collections/{collection}', [CollectionController::class, 'destroy']);
        Route::post('collections/{collection}/series', [CollectionController::class, 'addSeries']);
        Route::delete('collections/{collection}/series/{series}', [CollectionController::class, 'removeSeries']);
        // Comments
        Route::get('my-comments', [\App\Http\Controllers\Api\V1\CommentController::class, 'userComments']);
    });

    // ─── Author (role-guarded) ───
    Route::prefix('author')->middleware('author-only')->group(function () {
        // Dashboard & Counts
        Route::get('dashboard', [SeriesController::class, 'dashboard']);
        Route::get('series-counts', [SeriesController::class, 'counts']);

        // Series CRUD
        Route::get('series', [SeriesController::class, 'index']);
        Route::post('series', [SeriesController::class, 'store']);
        Route::put('series/{series}', [SeriesController::class, 'update']);
        Route::delete('series/{series}', [SeriesController::class, 'destroy']);
        Route::post('series/{series}/publish', [SeriesController::class, 'publish']);

        // Episodes
        Route::get('series/{series}/episodes', [EpisodeController::class, 'index']);
        Route::post('series/{series}/episodes', [EpisodeController::class, 'store']);
        Route::patch('episodes/{episode}', [EpisodeController::class, 'update']);
        Route::post('episodes/{episode}/publish', [EpisodeController::class, 'publish']);
        Route::delete('episodes/{episode}', [EpisodeController::class, 'destroy']);

        // Pages (R2 signed URL flow)
        Route::post('uploads/signed-url', [PageController::class, 'signedUrl'])->middleware('throttle:30,1');
        Route::get('episodes/{episode}/pages', [PageController::class, 'index']);
        Route::post('episodes/{episode}/pages', [PageController::class, 'store']);
        Route::put('pages/{page}', [PageController::class, 'replace']);
        Route::patch('episodes/{episode}/reorder', [PageController::class, 'reorder']);
        Route::delete('pages/{page}', [PageController::class, 'destroy']);

        // Analytics
        Route::get('analytics/overview', [AnalyticsController::class, 'overview']);
        Route::get('analytics/trend', [AnalyticsController::class, 'trend']);
        Route::get('analytics/top-series', [AnalyticsController::class, 'topSeries']);
        Route::get('analytics/top-episodes', [AnalyticsController::class, 'topEpisodes']);
    });

    // ═══════════════════════════════════════════════════════
    // STUB ROUTES — Future monetization (payment provider needed)
    // ═══════════════════════════════════════════════════════
    Route::prefix('subscriptions')->group(function () {
        Route::post('checkout', fn() => response()->json(['message' => 'Payment provider not configured'], 501));
        Route::get('active', fn() => response()->json(['subscription' => null, 'message' => 'No active subscription']));
        Route::post('cancel', fn() => response()->json(['message' => 'Payment provider not configured'], 501));
        Route::post('sync', fn() => response()->json(['message' => 'Payment provider not configured'], 501));
    });

    Route::prefix('gifts')->group(function () {
        Route::post('send', fn() => response()->json(['message' => 'Gifting not available yet'], 501));
        Route::get('received', fn() => response()->json(['gifts' => []]));
        Route::get('sent', fn() => response()->json(['gifts' => []]));
    });
});

// ─── Public Data (tanpa auth) ───
Route::prefix('v1/public')->group(function () {
    Route::get('genres', function () {
        return response()->json(
            \App\Models\Genre::orderBy('name')->get()
        );
    });

    Route::get('images/{path}', function ($path) {
        $temporaryUrl = \Illuminate\Support\Facades\Storage::disk('s3')->temporaryUrl(
            $path,
            now()->addMinutes(60)
        );
        return redirect($temporaryUrl);
    })->where('path', '.*');
});

// ═══════════════════════════════════════════════════════
// STUB: Payment Webhook (no auth — called by payment provider)
// ═══════════════════════════════════════════════════════
Route::prefix('v1/webhooks')->group(function () {
    Route::post('payment', fn() => response()->json(['message' => 'Payment provider not configured'], 501));
});
