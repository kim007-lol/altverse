<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;

class DailyLoginController extends Controller
{
    /**
     * POST /api/v1/daily-login
     * Record daily login for coin reward tracking.
     * NOTE: XP is NO LONGER awarded here — XP is only via Missions system.
     */
    public function claim(Request $request): JsonResponse
    {
        $user = $request->user();
        $cacheKey = "daily_login:{$user->id}:" . now()->toDateString();

        // Already claimed today
        if (Cache::has($cacheKey)) {
            return response()->json([
                'message' => 'Daily reward sudah diklaim hari ini',
                'already_claimed' => true,
            ]);
        }

        // Mark as claimed for today (expires at midnight)
        $secondsUntilMidnight = now()->endOfDay()->diffInSeconds(now());
        Cache::put($cacheKey, true, $secondsUntilMidnight);

        return response()->json([
            'message' => 'Daily login berhasil!',
            'already_claimed' => false,
        ]);
    }

    /**
     * GET /api/v1/daily-login/status
     * Check if daily login has been claimed today.
     */
    public function status(Request $request): JsonResponse
    {
        $user = $request->user();
        $cacheKey = "daily_login:{$user->id}:" . now()->toDateString();

        return response()->json([
            'claimed_today' => Cache::has($cacheKey),
        ]);
    }
}
