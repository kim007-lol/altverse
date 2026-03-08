<?php

namespace App\Http\Controllers\Api\V1\Reader;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\UserXp;
use App\Models\UserSeasonGlobal;
use App\Models\UserSeasonAuthor;
use App\Models\Season;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;

class ReaderProfileController extends Controller
{
    /**
     * GET /api/v1/reader/profile
     * Private profile (owner view) — full data with wallet, XP, season info.
     */
    public function me(Request $request)
    {
        $user = $request->user();
        $user->load('supporterLevel');
        $user->load(['badges' => function ($query) {
            $query->wherePivot('is_pinned', true);
        }]);

        $xp = UserXp::find($user->id);
        $season = Season::active()->first();

        $seasonGlobal = null;
        $seasonAuthorRanks = [];

        if ($season) {
            $seasonGlobal = UserSeasonGlobal::where('user_id', $user->id)
                ->where('season_id', $season->id)
                ->first();

            $seasonAuthorRanks = UserSeasonAuthor::where('user_id', $user->id)
                ->where('season_id', $season->id)
                ->where('xp', '>', 0)
                ->orderByDesc('xp')
                ->limit(5)
                ->with('author:id,name,pen_name,avatar_url')
                ->get();
        }

        return response()->json([
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'pen_name' => $user->pen_name,
                'avatar_url' => $user->avatar_url,
                'bio' => $user->bio,
                'coins' => $user->coins,
                'lifetime_spend' => $user->lifetime_spend,
                'supporter_level' => $user->supporterLevel,
                'created_at' => $user->created_at,
            ],
            'xp' => [
                'total_xp' => $xp?->total_xp ?? 0,
                'level' => $xp?->level ?? 0,
                'next_level_xp' => UserXp::xpForLevel(($xp?->level ?? 0) + 1),
            ],
            'season' => $season,
            'season_global' => $seasonGlobal,
            'season_author_ranks' => $seasonAuthorRanks,
            'stats' => [
                'following' => $user->following()->count(),
                'bookmarks' => $user->bookmarks()->count(),
                'unlocked_episodes' => $user->unlockedEpisodes()->count(),
            ],
            'pinned_badges' => $user->badges->map(fn($b) => [
                'id'       => $b->id,
                'name'     => $b->name,
                'icon_url' => $b->icon_url,
                'color'    => $b->color,
            ]),
        ]);
    }

    /**
     * GET /api/v1/reader/profile/{userId}
     * Public profile — enriched data for public viewing.
     */
    public function show(Request $request, int $userId)
    {
        $user = User::select(
            'id',
            'name',
            'pen_name',
            'avatar_url',
            'author_avatar_url',
            'bio',
            'author_bio',
            'social_links',
            'role',
            'supporter_level_id',
            'lifetime_spend',
            'followers_count',
            'created_at'
        )
            ->with('supporterLevel:id,name,icon,color')
            ->findOrFail($userId);

        // XP & Level
        $xp = UserXp::find($userId);
        $level = $xp?->level ?? 0;
        $currentXp = $xp?->total_xp ?? 0;
        $nextLevelXp = UserXp::xpForLevel($level + 1);

        // Badges
        $badges = $user->badges()
            ->select('badges.id', 'badges.key', 'badges.name', 'badges.description', 'badges.icon_url', 'badges.category', 'badges.condition_type', 'badges.color')
            ->get()
            ->map(fn($b) => [
                'id'          => $b->id,
                'key'         => $b->key,
                'name'        => $b->name,
                'description' => $b->description,
                'icon_url'    => $b->icon_url,
                'category'    => $b->category,
                'type'        => $b->condition_type ?? 'achievement',
                'color'       => $b->color,
                'earned_at'   => $b->pivot->earned_at,
                'is_pinned'   => $b->pivot->is_pinned,
            ]);

        // Stats — hide private counts from public viewers
        $isOwner = $request->user() && $request->user()->id === $userId;
        $stats = [
            'followers'  => $user->followers_count ?? 0,
            'following'  => $user->following()->count(),
        ];
        if ($isOwner) {
            $stats['unlocked'] = $user->unlockedEpisodes()->count();
            $stats['bookmarks'] = $user->bookmarks()->count();
        }

        // Is viewer following this user?
        $isFollowing = false;
        if ($request->user()) {
            $isFollowing = $request->user()->following()
                ->where('following_id', $userId)
                ->exists();
        }

        // Season rank
        $season = Season::active()->first();
        $seasonRank = null;
        if ($season) {
            $seasonRank = UserSeasonGlobal::where('user_id', $userId)
                ->where('season_id', $season->id)
                ->first(['xp', 'rank']);
        }

        return response()->json([
            'user' => $user,
            'xp' => [
                'level'         => $level,
                'current_xp'    => $currentXp,
                'next_level_xp' => $nextLevelXp,
            ],
            'badges'       => $badges,
            'stats'        => $stats,
            'is_following' => $isFollowing,
            'is_self'      => $isOwner,
            'season_rank'  => $seasonRank,
        ]);
    }
}
