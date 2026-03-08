<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Season;
use App\Models\SeasonSupporter;
use App\Models\SeasonAuthorEarning;
use App\Models\SupporterLevel;
use App\Models\UserSeasonGlobal;
use App\Models\UserXp;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;

class LeaderboardController extends Controller
{
    /**
     * GET /api/v1/leaderboard/overview
     * Returns current season info + user's own rank in all 3 leaderboards + supporter levels.
     */
    public function overview(Request $request)
    {
        $user = $request->user();
        $season = Season::active()->first();

        $data = [
            'season' => $season,
            'supporter_levels' => Cache::remember(
                'supporter_levels',
                3600,
                fn() =>
                SupporterLevel::orderBy('min_spend')->get()
            ),
        ];

        if ($season && $user) {
            // Top XP — user's own season XP
            $userGlobal = UserSeasonGlobal::where('user_id', $user->id)
                ->where('season_id', $season->id)
                ->first();

            // Top Supporter — user's own season spending
            $userSupporter = SeasonSupporter::where('user_id', $user->id)
                ->where('season_id', $season->id)
                ->first();

            // Top Author — user's own season earnings (if author)
            $userAuthorEarning = null;
            if ($user->isAuthor()) {
                $userAuthorEarning = SeasonAuthorEarning::where('author_id', $user->id)
                    ->where('season_id', $season->id)
                    ->first();
            }

            $userXp = UserXp::find($user->id);

            $data['my_season_xp'] = $userGlobal;
            $data['my_season_spending'] = $userSupporter;
            $data['my_season_earning'] = $userAuthorEarning;
            $data['my_xp'] = $userXp;
            $data['my_level'] = $userXp?->level ?? 0;
            $data['my_supporter_level'] = $user->supporterLevel;
            $data['next_level_xp'] = UserXp::xpForLevel(($userXp?->level ?? 0) + 1);
        }

        return response()->json($data);
    }

    /**
     * GET /api/v1/leaderboard/top-xp
     * Season Global XP leaderboard (top 50).
     * Pure engagement ranking — no coin-related XP.
     */
    public function topXp()
    {
        $season = Season::active()->first();
        if (!$season) {
            return response()->json(['data' => [], 'season' => null]);
        }

        $rankings = Cache::remember(
            "leaderboard:xp:{$season->id}",
            300,
            fn() =>
            UserSeasonGlobal::where('season_id', $season->id)
                ->orderByDesc('xp')
                ->limit(50)
                ->with('user:id,name,pen_name,avatar_url,author_avatar_url,role,supporter_level_id')
                ->get()
        );

        return response()->json([
            'data' => $rankings,
            'season' => $season,
        ]);
    }

    /**
     * GET /api/v1/leaderboard/top-supporters
     * Season-based coin spending leaderboard (top 50 readers).
     * Shows total coins spent during the active season.
     */
    public function topSupporters()
    {
        $season = Season::active()->first();
        if (!$season) {
            return response()->json(['data' => [], 'season' => null]);
        }

        $data = Cache::remember(
            "leaderboard:supporters:{$season->id}",
            300,
            fn() =>
            SeasonSupporter::where('season_id', $season->id)
                ->where('total_spent', '>', 0)
                ->orderByDesc('total_spent')
                ->limit(50)
                ->with([
                    'user:id,name,pen_name,avatar_url,author_avatar_url,role,supporter_level_id',
                    'user.supporterLevel:id,name,icon,color',
                ])
                ->get()
        );

        return response()->json([
            'data' => $data,
            'season' => $season,
        ]);
    }

    /**
     * GET /api/v1/leaderboard/top-authors
     * Season-based author earnings leaderboard (top 50 authors).
     * Shows total coins received during the active season.
     */
    public function topAuthors()
    {
        $season = Season::active()->first();
        if (!$season) {
            return response()->json(['data' => [], 'season' => null]);
        }

        $data = Cache::remember(
            "leaderboard:authors:{$season->id}",
            300,
            fn() =>
            SeasonAuthorEarning::where('season_id', $season->id)
                ->where('total_earned', '>', 0)
                ->orderByDesc('total_earned')
                ->limit(50)
                ->with('author:id,name,pen_name,avatar_url,author_avatar_url,author_tier')
                ->get()
        );

        return response()->json([
            'data' => $data,
            'season' => $season,
        ]);
    }

    /**
     * GET /api/v1/leaderboard/author/{authorId}/supporters
     * Top supporters for a specific author (per-author loyalty — lifetime).
     */
    public function authorSupporters(int $authorId)
    {
        $data = Cache::remember(
            "leaderboard:author:{$authorId}:supporters",
            300,
            fn() =>
            \App\Models\AuthorSupportTotal::where('author_id', $authorId)
                ->where('total_spend', '>', 0)
                ->orderByDesc('total_spend')
                ->limit(10)
                ->with('user:id,name,pen_name,avatar_url,author_avatar_url,role,supporter_level_id')
                ->with('user.supporterLevel:id,name,icon,color')
                ->get()
        );

        return response()->json(['data' => $data]);
    }
}
