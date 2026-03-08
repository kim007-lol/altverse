<?php

namespace App\Http\Controllers\Api\V1\Reader;

use App\Http\Controllers\Controller;
use App\Models\Genre;
use App\Models\Series;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;

class FypController extends Controller
{
    /** Homepage — Featured, Continue Reading, Trending, Recommended, Latest */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();

        // 1. Featured (top 5 all-time views — cached 10 min)
        $featured = Cache::remember('home:featured', 600, function () {
            return Series::with('author:id,name,pen_name,avatar_url')
                ->where('status', 'published')
                ->orderByDesc('total_views')
                ->limit(5)
                ->get(['id', 'title', 'slug', 'cover_url', 'synopsis', 'total_views', 'author_id']);
        });

        // 2. Continue Reading (personal — cached 5 min per user)
        $continueReading = Cache::remember("home:continue:{$user->id}", 300, function () use ($user) {
            return $user->readingHistories()
                ->with([
                    'series:id,title,slug,cover_url,author_id',
                    'series.author:id,name,pen_name,avatar_url',
                    'episode:id,title,episode_number',
                ])
                ->latest('read_at')
                ->limit(10)
                ->get()
                ->map(function ($h) {
                    if (!$h->series) return null;
                    return [
                        'series_id'      => $h->series_id,
                        'title'          => $h->series->title,
                        'cover_url'      => $h->series->cover_url,
                        'author'         => $h->series->author?->pen_name ?? $h->series->author?->name,
                        'last_episode'   => $h->episode?->title,
                        'episode_number' => $h->episode?->episode_number,
                        'last_page'      => $h->last_page,
                        'read_at'        => $h->read_at,
                    ];
                })
                ->filter()
                ->values();
        });

        // 3. Trending (by total views, different from featured — cached 10 min)
        $trending = Cache::remember('home:trending', 600, function () {
            return Series::with('author:id,name,pen_name,avatar_url')
                ->withCount('episodes')
                ->where('status', 'published')
                ->orderByDesc('total_views')
                ->offset(5) // Skip featured items
                ->limit(15)
                ->get(['id', 'title', 'slug', 'cover_url', 'genre', 'total_views', 'author_id']);
        });

        // 4. Recommended / FYP (genre-based — cached 5 min per user)
        $recommended = Cache::remember("home:fyp:{$user->id}", 300, function () use ($user) {
            $preferredGenreIds = $user->genrePreferences()->pluck('genre_id');

            return Series::with('author:id,name,pen_name,avatar_url')
                ->withCount('episodes')
                ->where('status', 'published')
                ->when($preferredGenreIds->isNotEmpty(), function ($q) use ($preferredGenreIds) {
                    $q->whereHas('genres', fn($g) => $g->whereIn('genres.id', $preferredGenreIds));
                })
                ->inRandomOrder()
                ->limit(15)
                ->get(['id', 'title', 'slug', 'cover_url', 'genre', 'total_views', 'author_id']);
        });

        // 5. Latest Updates (recently updated series — cached 5 min)
        $latest = Cache::remember('home:latest', 300, function () {
            return Series::with('author:id,name,pen_name,avatar_url')
                ->withCount('episodes')
                ->where('status', 'published')
                ->orderByDesc('updated_at')
                ->limit(15)
                ->get(['id', 'title', 'slug', 'cover_url', 'genre', 'total_views', 'author_id', 'updated_at']);
        });

        // 6. New Releases (newly published series — cached 5 min)
        $newReleases = Cache::remember('home:new_releases', 300, function () {
            return Series::with('author:id,name,pen_name,avatar_url')
                ->withCount('episodes')
                ->where('status', 'published')
                ->orderByDesc('created_at')
                ->limit(10)
                ->get(['id', 'title', 'slug', 'cover_url', 'genre', 'total_views', 'author_id', 'created_at']);
        });

        // 7. Genres (cached 1 hour)
        $genres = Cache::remember('genres:all', 3600, function () {
            return Genre::orderBy('name')->get();
        });

        return response()->json([
            'featured'         => $featured,
            'continue_reading' => $continueReading,
            'trending'         => $trending,
            'recommended'      => $recommended,
            'latest'           => $latest,
            'new_releases'     => $newReleases,
            'genres'           => $genres,
        ]);
    }
}
