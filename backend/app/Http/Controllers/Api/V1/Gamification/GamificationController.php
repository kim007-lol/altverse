<?php

namespace App\Http\Controllers\Api\V1\Gamification;

use App\Http\Controllers\Controller;
use App\Models\DailyXpLog;
use App\Models\UserXp;
use App\Services\XpService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class GamificationController extends Controller
{
    /**
     * GET /api/v1/gamification/daily-status
     *
     * Returns the user's daily XP progress for each activity type,
     * including current earned vs daily cap, so the frontend can
     * display transparent progress bars.
     */
    public function dailyStatus(Request $request): JsonResponse
    {
        $user = $request->user();
        $today = now()->toDateString();

        // Fetch today's XP logs for this user
        $logs = DailyXpLog::where('user_id', $user->id)
            ->where('date', $today)
            ->get()
            ->keyBy('activity');

        // Build progress array matching the XP caps in XpService
        $activities = [
            'comment' => [
                'label'        => 'Komentar',
                'icon'         => '💬',
                'xp_per_action' => 5,
                'max_xp'       => 50,
                'max_actions'  => 10,
            ],
            'like_received' => [
                'label'        => 'Like Diterima',
                'icon'         => '❤️',
                'xp_per_action' => 2,
                'max_xp'       => 40,
                'max_actions'  => 20,
            ],
            'daily_login' => [
                'label'        => 'Daily Login',
                'icon'         => '🚪',
                'xp_per_action' => 5,
                'max_xp'       => 5,
                'max_actions'  => 1,
            ],
            'reading_complete' => [
                'label'        => 'Baca Episode',
                'icon'         => '📖',
                'xp_per_action' => 3,
                'max_xp'       => 30,
                'max_actions'  => 10,
            ],
        ];

        $dailyProgress = [];
        $totalEarnedToday = 0;
        $totalMaxToday = 0;

        foreach ($activities as $key => $meta) {
            $log = $logs->get($key);
            $earned = $log ? $log->xp_earned : 0;
            $actions = $log ? $log->action_count : 0;

            $dailyProgress[] = [
                'activity'      => $key,
                'label'         => $meta['label'],
                'icon'          => $meta['icon'],
                'xp_earned'     => $earned,
                'max_xp'        => $meta['max_xp'],
                'action_count'  => $actions,
                'max_actions'   => $meta['max_actions'],
                'is_maxed'      => $earned >= $meta['max_xp'],
            ];

            $totalEarnedToday += $earned;
            $totalMaxToday += $meta['max_xp'];
        }

        // Get XP and level info
        $xpRecord = UserXp::find($user->id);
        $level = $xpRecord?->level ?? 0;
        $totalXp = $xpRecord?->total_xp ?? 0;
        $nextLevelXp = UserXp::xpForLevel($level + 1);
        $currentLevelXp = UserXp::xpForLevel($level);

        return response()->json([
            'daily_progress'    => $dailyProgress,
            'total_earned_today' => $totalEarnedToday,
            'total_max_today'   => $totalMaxToday,
            'level'             => $level,
            'total_xp'          => $totalXp,
            'current_level_xp'  => $currentLevelXp,
            'next_level_xp'     => $nextLevelXp,
            'xp_in_level'       => $totalXp - $currentLevelXp,
            'xp_needed'         => $nextLevelXp - $currentLevelXp,
        ]);
    }
}
