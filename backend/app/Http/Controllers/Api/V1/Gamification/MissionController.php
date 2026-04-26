<?php

namespace App\Http\Controllers\Api\V1\Gamification;

use App\Http\Controllers\Controller;
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
            'success' => true,
            'missions' => $missions
        ]);
    }

    /**
     * Claim a mission reward.
     */
    public function claim(Request $request, int $missionId): JsonResponse
    {
        $result = $this->missionService->claimReward($request->user(), $missionId);

        return response()->json($result, $result['success'] ? 200 : 400);
    }
}
