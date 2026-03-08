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
     * Get all active missions along with progress.
     */
    public function index(Request $request): JsonResponse
    {
        $missions = $this->missionService->getMissions($request->user());

        return response()->json([
            'missions' => $missions
        ]);
    }

    /**
     * Claim a specific mission.
     */
    public function claim(Request $request, string $code): JsonResponse
    {
        $result = $this->missionService->claimMission($request->user(), $code);

        $statusCode = $result['code'] ?? 200;
        unset($result['code']);

        return response()->json(
            $result,
            $statusCode
        );
    }
}
