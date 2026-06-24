<?php

namespace App\Http\Controllers\Api\V1\Gamification;

use App\Http\Controllers\Controller;
use App\Models\Mission;
use App\Models\UserMission;
use App\Services\MissionService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class MissionController extends Controller
{
    protected MissionService $missionService;

    public function __construct(MissionService $missionService)
    {
        $this->missionService = $missionService;
    }

    /**
     * Get all active missions along with user progress.
     */
    public function index(Request $request): JsonResponse
    {
        $missions = $this->missionService->getUserMissions($request->user());

        return response()->json([
            'success'  => true,
            'missions' => $missions
        ]);
    }

    /**
     * Claim a single mission reward.
     */
    public function claim(Request $request, int $missionId): JsonResponse
    {
        $result = $this->missionService->claimReward($request->user(), $missionId);

        return response()->json($result, $result['success'] ? 200 : 400);
    }

    /**
     * Claim ALL claimable missions at once.
     * Returns a summary of total XP and coins earned.
     */
    public function claimAll(Request $request): JsonResponse
    {
        $user = $request->user();

        // Find every completed-but-unclaimed mission for this user
        $claimableIds = UserMission::where('user_id', $user->id)
            ->whereNotNull('completed_at')
            ->whereNull('claimed_at')
            ->pluck('mission_id');

        if ($claimableIds->isEmpty()) {
            return response()->json([
                'success' => false,
                'message' => 'Tidak ada mission yang bisa diklaim',
            ], 422);
        }

        $totalXp    = 0;
        $totalCoins = 0;
        $claimed    = [];

        foreach ($claimableIds as $missionId) {
            $result = $this->missionService->claimReward($user, $missionId);
            if ($result['success']) {
                $totalXp    += $result['data']['xp_reward']    ?? 0;
                $totalCoins += $result['data']['coin_reward']   ?? 0;
                $claimed[]   = $missionId;
            }
        }

        return response()->json([
            'success'       => true,
            'message'       => count($claimed) . ' mission berhasil diklaim!',
            'claimed_count' => count($claimed),
            'total_xp'      => $totalXp,
            'total_coins'   => $totalCoins,
        ]);
    }
}
