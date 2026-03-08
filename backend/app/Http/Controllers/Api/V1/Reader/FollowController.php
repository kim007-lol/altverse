<?php

namespace App\Http\Controllers\Api\V1\Reader;

use App\Http\Controllers\Controller;
use App\Jobs\RecalculateAuthorTierJob;
use App\Models\AuthorSupportTotal;
use App\Models\User;
use App\Services\BadgeService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class FollowController extends Controller
{
    /** Get list of authors the user is following */
    public function following(Request $request): JsonResponse
    {
        $following = $request->user()
            ->following()
            ->select('users.id', 'name', 'pen_name', 'avatar_url', 'bio', 'author_tier')
            ->withCount(['followers', 'series'])
            ->latest('follows.created_at')
            ->paginate(20);

        return response()->json($following);
    }

    /** Get followers of current user (for author) */
    public function followers(Request $request): JsonResponse
    {
        $followers = $request->user()
            ->followers()
            ->select('users.id', 'name', 'pen_name', 'avatar_url')
            ->latest('follows.created_at')
            ->paginate(20);

        return response()->json($followers);
    }

    /** Toggle follow/unfollow with denormalized counter */
    public function toggle(Request $request, User $user): JsonResponse
    {
        $currentUser = $request->user();

        if ($currentUser->id === $user->id) {
            return response()->json(['message' => 'Tidak bisa follow diri sendiri'], 422);
        }

        $isFollowing = $currentUser->following()->where('following_id', $user->id)->exists();

        DB::transaction(function () use ($currentUser, $user, $isFollowing) {
            if ($isFollowing) {
                $currentUser->following()->detach($user->id);
                // Guard: prevent negative followers_count
                User::where('id', $user->id)->where('followers_count', '>', 0)->decrement('followers_count');
            } else {
                $currentUser->following()->attach($user->id);
                User::where('id', $user->id)->increment('followers_count');

                // Notification — use role-aware display name
                $displayName = $currentUser->role === 'author' ? $currentUser->pen_name : $currentUser->name;
                \App\Models\Notification::create([
                    'id'          => Str::uuid(),
                    'user_id'     => $user->id,
                    'type'        => 'new_follower',
                    'target_role' => 'author',
                    'title'       => 'Follower Baru',
                    'body'        => "{$displayName} mulai mengikuti kamu",
                    'data'        => ['sender_id' => $currentUser->id],
                ]);
            }
        });

        // Invalidate caches
        Cache::forget("author:{$user->id}:dashboard");

        // Dispatch tier recalculation
        RecalculateAuthorTierJob::dispatch($user->id);

        // Auto-grant follower badges
        $user->refresh();
        BadgeService::grantFollowerBadges($user);

        return response()->json([
            'message'   => $isFollowing ? 'Unfollow berhasil' : 'Follow berhasil',
            'following' => !$isFollowing,
        ]);
    }

    /** Check if following */
    public function check(Request $request, User $user): JsonResponse
    {
        $isFollowing = $request->user()->following()->where('following_id', $user->id)->exists();
        return response()->json(['following' => $isFollowing]);
    }

    /** Get author public profile (enriched) */
    public function authorProfile(Request $request, User $user): JsonResponse
    {
        if (empty($user->pen_name)) {
            return response()->json(['message' => 'User tidak memiliki profil author'], 404);
        }

        $user->loadCount(['followers', 'series']);

        // Badges earned by this author
        $badges = $user->badges()
            ->select('badges.id', 'key', 'name', 'description', 'icon_url', 'category', 'condition_type', 'condition_value', 'color')
            ->orderByDesc('condition_value')
            ->get()
            ->map(fn($b) => [
                'id'          => $b->id,
                'key'         => $b->key,
                'name'        => $b->name,
                'description' => $b->description,
                'icon_url'    => $b->icon_url,
                'category'    => $b->category,
                'color'       => $b->color,
                'earned_at'   => $b->pivot->earned_at,
                'is_pinned'   => $b->pivot->is_pinned,
            ]);

        // Highest follower badge
        $highestBadge = BadgeService::getHighestFollowerBadge($user);

        // Is current user following?
        $isFollowing = false;
        if ($request->user()) {
            $isFollowing = $request->user()->following()->where('following_id', $user->id)->exists();
        }

        // Top 5 supporters
        $topSupporters = AuthorSupportTotal::where('author_id', $user->id)
            ->with('user:id,name,pen_name,avatar_url')
            ->orderByDesc('total_spend')
            ->limit(5)
            ->get()
            ->map(fn($s) => [
                'user'        => $s->user?->only(['id', 'name', 'pen_name', 'avatar_url']),
                'total_spend' => $s->total_spend,
            ]);

        // Is the viewer looking at their own author profile?
        $isSelf = $request->user() && $request->user()->id === $user->id;

        return response()->json([
            'author' => array_merge($user->only([
                'id',
                'name',
                'pen_name',
                'avatar_url',
                'author_avatar_url',
                'bio',
                'author_bio',
                'social_links',
                'author_tier',
                'followers_count',
                'series_count',
                'total_views',
                'can_customize_banner',
                'can_tip',
                'is_verified',
            ]), [
                'highest_badge' => $highestBadge ? [
                    'name'  => $highestBadge->name,
                    'color' => $highestBadge->color,
                ] : null,
            ]),
            'badges'         => $badges,
            'is_following'   => $isFollowing,
            'is_self'        => $isSelf,
            'top_supporters' => $topSupporters,
            'series'         => $user->series()
                ->where('status', 'published')
                ->withCount('episodes')
                ->latest()
                ->limit(20)
                ->get(),
        ]);
    }
}
