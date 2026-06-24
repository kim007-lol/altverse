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
     * - Advanced filters: age_rating, is_premium, status
     * - Paginated with Redis cache (60s per page)
     */
    public function index(Request $request): JsonResponse
    {
        $genre = $request->input('genre');
        $sort  = $request->input('sort', 'trending');
        $q     = $request->input('q');
        $page  = $request->input('page', 1);
        
        // Advanced filters
        $ageRating = $request->input('age_rating');
        $isPremium = $request->input('is_premium');
        $status = $request->input('status', 'published');

        // If searching by keyword, bypass cache
        if ($q) {
            return $this->searchByKeyword($request);
        }

        // Cache key with filters
        $cacheKey = "discover:" . ($genre ?: 'all') . ":{$sort}:{$ageRating}:{$isPremium}:{$status}:page:{$page}";

        $result = Cache::remember($cacheKey, 60, function () use ($genre, $sort, $ageRating, $isPremium, $status) {
            $query = Series::with(['author:id,name,pen_name,avatar_url,author_tier'])
                ->withCount('episodes')
                ->where('status', $status);

            // Genre filter
            if ($genre && $genre !== 'all') {
                $query->where('genre', 'LIKE', "%{$genre}%");
            }
            
            // Age rating filter
            if ($ageRating) {
                $query->where('age_rating', $ageRating);
            }
            
            // Premium filter
            if ($isPremium !== null) {
                $query->where('is_premium', $isPremium === 'true' || $isPremium === '1');
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
        $ageRating = $request->input('age_rating');
        $isPremium = $request->input('is_premium');
        $status = $request->input('status', 'published');
        
        // Track search history if user is authenticated
        if ($request->user()) {
            $this->trackSearchHistory($request->user()->id, $q);
        }

        // ── User search (dual-profile: split Reader & Author identities) ──
        $rawUsers = \App\Models\User::select('id', 'username', 'name', 'pen_name', 'avatar_url', 'author_avatar_url', 'role', 'bio', 'author_bio', 'level', 'supporter_level_id', 'followers_count', 'author_tier')
            ->with([
                'supporterLevel:id,name,icon,color',
                'badges' => function ($query) {
                    $query->wherePivot('is_pinned', true);
                }
            ])
            ->where(function ($qb) use ($q) {
                $qb->where('username', 'LIKE', "%{$q}%")
                    ->orWhere('name', 'LIKE', "%{$q}%")
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
            $usernameMatches = $u->username && stripos($u->username, $q) !== false;

            // Emit Reader profile if name or username matches the query
            if ($nameMatches || $usernameMatches) {
                $users->push([
                    'id'              => $u->id,
                    'username'        => $u->username,
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

            // Emit Author profile if pen_name OR username matches the query, and user has a pen_name
            if (($penNameMatches || $usernameMatches) && !empty($u->pen_name)) {
                $users->push([
                    'id'              => $u->id,
                    'username'        => $u->username,
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
                    'author_tier'     => $u->author_tier,
                    'pinned_badges'   => $badgeList,
                ]);
            }

            // If neither specifically matched (shouldn't happen), emit based on current role
            if (!$nameMatches && !$penNameMatches && !$usernameMatches) {
                $users->push([
                    'id'              => $u->id,
                    'username'        => $u->username,
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
                    'author_tier'     => $u->author_tier,
                    'pinned_badges'   => $badgeList,
                ]);
            }
        }

        // ── Series search with full-text search ──
        $query = Series::with(['author:id,name,pen_name,avatar_url,author_tier'])
            ->withCount('episodes')
            ->where('status', $status);

        // Full-text search using PostgreSQL
        // Use ILIKE for case-insensitive search
        $query->where(function ($qb) use ($q) {
            $qb->where('title', 'ILIKE', "%{$q}%")
                ->orWhere('synopsis', 'ILIKE', "%{$q}%")
                ->orWhereHas('author', fn($a) => $a->where('name', 'ILIKE', "%{$q}%")
                    ->orWhere('pen_name', 'ILIKE', "%{$q}%"));
        });

        // Genre filter
        if ($genre && $genre !== 'all') {
            $query->where('genre', 'LIKE', "%{$genre}%");
        }
        
        // Age rating filter
        if ($ageRating) {
            $query->where('age_rating', $ageRating);
        }
        
        // Premium filter
        if ($isPremium !== null) {
            $query->where('is_premium', $isPremium === 'true' || $isPremium === '1');
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
    
    /**
     * Track search history for personalization
     */
    private function trackSearchHistory(int $userId, string $query): void
    {
        try {
            \Illuminate\Support\Facades\DB::table('search_history')->insert([
                'user_id' => $userId,
                'query' => $query,
                'created_at' => now(),
            ]);
        } catch (\Exception $e) {
            // Silently fail if table doesn't exist yet
        }
    }
    
    /**
     * Get search suggestions based on popular searches
     */
    public function suggestions(Request $request): JsonResponse
    {
        $q = $request->input('q', '');
        
        if (strlen($q) < 2) {
            return response()->json(['suggestions' => []]);
        }
        
        // Get popular series titles that match
        $seriesSuggestions = Series::where('status', 'published')
            ->where('title', 'ILIKE', "%{$q}%")
            ->orderByDesc('total_views')
            ->limit(5)
            ->pluck('title');
            
        // Get popular author names that match
        $authorSuggestions = \App\Models\User::where(function ($query) use ($q) {
                $query->where('name', 'ILIKE', "%{$q}%")
                    ->orWhere('pen_name', 'ILIKE', "%{$q}%");
            })
            ->orderByDesc('followers_count')
            ->limit(5)
            ->get()
            ->map(fn($u) => $u->pen_name ?? $u->name);
        
        $suggestions = $seriesSuggestions->merge($authorSuggestions)
            ->unique()
            ->take(10)
            ->values();
        
        return response()->json(['suggestions' => $suggestions]);
    }
    
    /**
     * Get user's search history
     */
    public function history(Request $request): JsonResponse
    {
        try {
            $history = \Illuminate\Support\Facades\DB::table('search_history')
                ->where('user_id', $request->user()->id)
                ->orderByDesc('created_at')
                ->limit(20)
                ->pluck('query')
                ->unique()
                ->values();
                
            return response()->json(['history' => $history]);
        } catch (\Exception $e) {
            return response()->json(['history' => []]);
        }
    }
    
    /**
     * Clear user's search history
     */
    public function clearHistory(Request $request): JsonResponse
    {
        try {
            \Illuminate\Support\Facades\DB::table('search_history')
                ->where('user_id', $request->user()->id)
                ->delete();
                
            return response()->json(['message' => 'Riwayat pencarian berhasil dihapus']);
        } catch (\Exception $e) {
            return response()->json(['message' => 'Gagal menghapus riwayat pencarian'], 500);
        }
    }
}
