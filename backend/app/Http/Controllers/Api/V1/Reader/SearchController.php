<?php

namespace App\Http\Controllers\Api\V1\Reader;

use App\Http\Controllers\Controller;
use App\Models\Series;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;

class SearchController extends Controller
{
    /**
     * Discover / Ranking Engine
     * - Global ranking (genre=all) or per-genre ranking
     * - Sort: trending (default), popular, new, monthly
     * - Search by keyword (title, author name/pen_name)
     * - Paginated with Redis cache (60s per page)
     */
    public function index(Request $request): JsonResponse
    {
        $genre = $request->input('genre');
        $sort  = $request->input('sort', 'trending');
        $q     = $request->input('q');
        $page  = $request->input('page', 1);

        // If searching by keyword, bypass cache
        if ($q) {
            return $this->searchByKeyword($request);
        }

        // Cache key: discover:{genre}:{sort}:page:{n}
        $cacheKey = "discover:" . ($genre ?: 'all') . ":{$sort}:page:{$page}";

        $result = Cache::remember($cacheKey, 60, function () use ($genre, $sort) {
            $query = Series::with(['author:id,name,pen_name,avatar_url'])
                ->withCount('episodes')
                ->where('status', 'published');

            // Genre filter
            if ($genre && $genre !== 'all') {
                $query->where('genre', 'LIKE', "%{$genre}%");
            }

            // Sort strategy
            $query = match ($sort) {
                'popular'  => $query->orderByDesc('total_views'),
                'new'      => $query->orderByDesc('created_at'),
                'liked'    => $query->orderByDesc('total_likes'),
                default    => $query->orderByDesc('total_views'), // trending = popular for now
            };

            return $query->paginate(15);
        });

        return response()->json([
            'data'         => $result->items(),
            'total'        => $result->total(),
            'current_page' => $result->currentPage(),
            'last_page'    => $result->lastPage(),
        ]);
    }

    /** Keyword search (not cached — user-specific) */
    private function searchByKeyword(Request $request): JsonResponse
    {
        $q = $request->input('q');
        $genre = $request->input('genre');
        $sort = $request->input('sort', 'trending');

        // ── User search (dual-profile: split Reader & Author identities) ──
        $rawUsers = \App\Models\User::select('id', 'name', 'pen_name', 'avatar_url', 'author_avatar_url', 'role', 'bio', 'author_bio', 'level', 'supporter_level_id', 'followers_count')
            ->with([
                'supporterLevel:id,name,icon,color',
                'badges' => function ($query) {
                    $query->wherePivot('is_pinned', true);
                }
            ])
            ->where(function ($qb) use ($q) {
                $qb->where('name', 'LIKE', "%{$q}%")
                    ->orWhere('pen_name', 'LIKE', "%{$q}%");
            })
            ->orderByDesc('followers_count')
            ->limit(10)
            ->get();

        // Split each user into separate Reader and Author virtual profiles
        $users = collect();
        foreach ($rawUsers as $u) {
            $badgeList = $u->badges->map(fn($b) => [
                'id'       => $b->id,
                'name'     => $b->name,
                'icon_url' => $b->icon_url,
                'color'    => $b->color,
            ]);

            $nameMatches = $u->name && stripos($u->name, $q) !== false;
            $penNameMatches = $u->pen_name && stripos($u->pen_name, $q) !== false;

            // Emit Reader profile if name matches the query
            if ($nameMatches) {
                $users->push([
                    'id'              => $u->id,
                    'name'            => $u->name,
                    'pen_name'        => null,
                    'avatar_url'      => $u->avatar_url,
                    'author_avatar_url' => null,
                    'role'            => 'reader',
                    'bio'             => $u->bio,
                    'author_bio'      => null,
                    'level'           => $u->level ?? 0,
                    'followers_count' => $u->followers_count ?? 0,
                    'supporter_level' => $u->supporterLevel,
                    'pinned_badges'   => $badgeList,
                ]);
            }

            // Emit Author profile if pen_name matches the query
            if ($penNameMatches) {
                $users->push([
                    'id'              => $u->id,
                    'name'            => $u->pen_name,
                    'pen_name'        => $u->pen_name,
                    'avatar_url'      => $u->author_avatar_url ?? $u->avatar_url,
                    'author_avatar_url' => $u->author_avatar_url,
                    'role'            => 'author',
                    'bio'             => $u->author_bio ?? $u->bio,
                    'author_bio'      => $u->author_bio,
                    'level'           => $u->level ?? 0,
                    'followers_count' => $u->followers_count ?? 0,
                    'supporter_level' => $u->supporterLevel,
                    'pinned_badges'   => $badgeList,
                ]);
            }

            // If neither specifically matched (shouldn't happen), emit based on current role
            if (!$nameMatches && !$penNameMatches) {
                $users->push([
                    'id'              => $u->id,
                    'name'            => $u->role === 'author' ? ($u->pen_name ?? $u->name) : $u->name,
                    'pen_name'        => $u->pen_name,
                    'avatar_url'      => $u->role === 'author' ? ($u->author_avatar_url ?? $u->avatar_url) : $u->avatar_url,
                    'author_avatar_url' => $u->author_avatar_url,
                    'role'            => $u->role,
                    'bio'             => $u->role === 'author' ? ($u->author_bio ?? $u->bio) : $u->bio,
                    'author_bio'      => $u->author_bio,
                    'level'           => $u->level ?? 0,
                    'followers_count' => $u->followers_count ?? 0,
                    'supporter_level' => $u->supporterLevel,
                    'pinned_badges'   => $badgeList,
                ]);
            }
        }

        // ── Series search ──
        $query = Series::with(['author:id,name,pen_name,avatar_url'])
            ->withCount('episodes')
            ->where('status', 'published');

        // Keyword search
        $query->where(function ($qb) use ($q) {
            $qb->where('title', 'LIKE', "%{$q}%")
                ->orWhere('synopsis', 'LIKE', "%{$q}%")
                ->orWhereHas('author', fn($a) => $a->where('name', 'LIKE', "%{$q}%")
                    ->orWhere('pen_name', 'LIKE', "%{$q}%"));
        });

        // Genre filter
        if ($genre && $genre !== 'all') {
            $query->where('genre', 'LIKE', "%{$genre}%");
        }

        $query = match ($sort) {
            'popular'  => $query->orderByDesc('total_views'),
            'new'      => $query->orderByDesc('created_at'),
            'liked'    => $query->orderByDesc('total_likes'),
            default    => $query->orderByDesc('total_views'),
        };

        $result = $query->paginate(15);

        return response()->json([
            'users'        => $users,
            'data'         => $result->items(),
            'total'        => $result->total(),
            'current_page' => $result->currentPage(),
            'last_page'    => $result->lastPage(),
        ]);
    }
}
