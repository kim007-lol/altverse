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
        Route::get('preferences', [NotificationController::class, 'preferences']);
        Route::put('preferences', [NotificationController::class, 'updatePreferences']);
        Route::delete('cleanup', [NotificationController::class, 'cleanup']);
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
        Route::post('{mission}/claim', [MissionController::class, 'claim']);
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
    
    // ── Reports (semua role) ──
    Route::prefix('reports')->group(function () {
        Route::get('reasons', [\App\Http\Controllers\Api\V1\ReportController::class, 'reasons']);
        Route::get('/', [\App\Http\Controllers\Api\V1\ReportController::class, 'index']);
        Route::post('/', [\App\Http\Controllers\Api\V1\ReportController::class, 'store']);
        Route::get('{report}', [\App\Http\Controllers\Api\V1\ReportController::class, 'show']);
        Route::delete('{report}', [\App\Http\Controllers\Api\V1\ReportController::class, 'destroy']);
    });

    // ─── Shared Reader Endpoints (Accessible to both Readers and Authors) ───
    Route::prefix('reader')->group(function () {
        // Public Profiles
        Route::get('profile/{user}', [ReaderProfileController::class, 'show']);
        Route::get('author/{user}/profile', [FollowController::class, 'authorProfile']);

        // Following
        Route::get('following', [FollowController::class, 'following']);
        Route::get('followers', [FollowController::class, 'followers']);
        Route::post('follow/{user}/toggle', [FollowController::class, 'toggle']);
        Route::get('follow/{user}/check', [FollowController::class, 'check']);
    });

    // ─── Reader (role-guarded) ───
    Route::prefix('reader')->middleware('reader-only')->group(function () {
        // FYP & Search
        Route::get('fyp', [FypController::class, 'index']);
        Route::get('search', [SearchController::class, 'index']);
        Route::get('search/suggestions', [SearchController::class, 'suggestions']);
        Route::get('search/history', [SearchController::class, 'history']);
        Route::delete('search/history', [SearchController::class, 'clearHistory']);

        // Private Profile (My Profile)
        Route::get('profile', [ReaderProfileController::class, 'me']);

        // Bookmarks
        Route::get('bookmarks', [BookmarkController::class, 'index']);
        Route::post('bookmarks/{series}/toggle', [BookmarkController::class, 'toggle']);
        Route::get('bookmarks/{series}/check', [BookmarkController::class, 'check']);

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
        Route::get('my-comments', [CommentController::class, 'userComments']);

        // Top-Up (Midtrans)
        Route::get('topup/packages', [\App\Http\Controllers\Api\V1\Reader\TopUpController::class, 'packages']);
        Route::get('topup/history', [\App\Http\Controllers\Api\V1\Reader\TopUpController::class, 'history']);
        Route::post('topup/create', [\App\Http\Controllers\Api\V1\Reader\TopUpController::class, 'create']);
        Route::post('topup/check-status', [\App\Http\Controllers\Api\V1\Reader\TopUpController::class, 'checkStatus']);
    });

    // ─── Author (role-guarded) ───
    Route::prefix('author')->middleware('author-only')->group(function () {
        // Dashboard & Counts
        Route::get('dashboard', [SeriesController::class, 'dashboard']);
        Route::get('series-counts', [SeriesController::class, 'counts']);

        // Withdrawal
        Route::get('withdrawals', [\App\Http\Controllers\Api\V1\Author\WithdrawalController::class, 'index']);
        Route::post('withdrawals', [\App\Http\Controllers\Api\V1\Author\WithdrawalController::class, 'store']);

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
        Route::get('analytics/engagement', [AnalyticsController::class, 'engagement']);
        Route::get('analytics/export', [AnalyticsController::class, 'export']);
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
        // Stream image directly from R2/S3 through Laravel
        // (R2 presigned GET URLs return 403, and public URL is not enabled)
        /** @var \Illuminate\Filesystem\FilesystemAdapter $disk */
        $disk = \Illuminate\Support\Facades\Storage::disk('s3');

        if (!$disk->exists($path)) {
            abort(404, 'Image not found');
        }

        $file = $disk->get($path);
        $mimeType = $disk->mimeType($path) ?: 'image/jpeg';
        $size = $disk->size($path);
        $lastModified = $disk->lastModified($path);

        return response($file, 200)
            ->header('Content-Type', $mimeType)
            ->header('Content-Length', $size)
            ->header('Cache-Control', 'public, max-age=86400') // 24h cache
            ->header('Last-Modified', gmdate('D, d M Y H:i:s', $lastModified) . ' GMT')
            ->header('ETag', '"' . md5($path . $lastModified) . '"');
    })->where('path', '.*');
});

// ═══════════════════════════════════════════════════════
// Midtrans Payment Webhook (no auth — validated via signature)
// ═══════════════════════════════════════════════════════
Route::prefix('v1/webhooks')->group(function () {
    Route::post('midtrans', [\App\Http\Controllers\Api\V1\MidtransWebhookController::class, 'handle']);
});
