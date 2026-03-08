<?php

namespace App\Http\Controllers\Api\V1\Author;

use App\Http\Controllers\Controller;
use App\Models\Series;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class SeriesController extends Controller
{
    /** List author's series */
    public function index(Request $request)
    {
        $series = Series::where('author_id', $request->user()->id)
            ->withCount('episodes')
            ->orderBy('updated_at', 'desc')
            ->get();

        return response()->json($series);
    }

    /** Series counts by status (cached) */
    public function counts(Request $request)
    {
        $userId = $request->user()->id;
        $cacheKey = "author:{$userId}:series_counts";

        $counts = Cache::remember($cacheKey, 300, function () use ($userId) {
            return [
                'draft'     => Series::where('author_id', $userId)->where('status', 'draft')->count(),
                'published' => Series::where('author_id', $userId)->where('status', 'published')->count(),
                'archived'  => Series::where('author_id', $userId)->where('status', 'archived')->count(),
                'total'     => Series::where('author_id', $userId)->count(),
            ];
        });

        return response()->json($counts);
    }

    /** Create new Series (draft) */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'title'       => 'required|string|max:255',
            'description' => 'nullable|string',
            'genre'       => 'required|string',
            'age_rating'  => 'required|in:all,13+,17+,18+',
            'cover'       => 'nullable|image|max:4096',
        ]);

        // Upload cover ke R2 jika ada
        $coverUrl = null;
        if ($request->hasFile('cover')) {
            $path = $request->file('cover')->store('covers', 's3');
            $coverUrl = $path; // simpan relative path, Flutter resolve via R2 public URL
        }

        $series = Series::create([
            'author_id'  => $request->user()->id,
            'title'      => $validated['title'],
            'slug'       => Str::slug($validated['title']) . '-' . Str::random(5),
            'synopsis'   => $validated['description'],
            'genre'      => $validated['genre'],
            'age_rating' => $validated['age_rating'],
            'cover_url'  => $coverUrl,
            'status'     => 'draft',
        ]);

        // Invalidate counts cache
        $this->invalidateCountsCache($request->user()->id);

        return response()->json($series, 201);
    }

    /** Update series metadata */
    public function update(Request $request, Series $series)
    {
        abort_if($series->author_id !== $request->user()->id, 403);

        $validated = $request->validate([
            'title'       => 'sometimes|string|max:255',
            'description' => 'nullable|string',
            'genre'       => 'sometimes|string',
            'age_rating'  => 'sometimes|in:all,13+,17+,18+',
            'cover'       => 'nullable|image|max:4096',
            'status'      => 'sometimes|in:draft,published,archived',
        ]);

        if ($request->hasFile('cover')) {
            $path = $request->file('cover')->store('covers', 's3');
            $series->cover_url = $path; // relative path
        }

        $series->fill([
            'title'      => $validated['title'] ?? $series->title,
            'synopsis'   => $validated['description'] ?? $series->synopsis,
            'genre'      => $validated['genre'] ?? $series->genre,
            'age_rating' => $validated['age_rating'] ?? $series->age_rating,
            'status'     => $validated['status'] ?? $series->status,
        ]);

        if (isset($validated['title'])) {
            $series->slug = Str::slug($validated['title']) . '-' . Str::random(5);
        }

        $statusChanged = $series->isDirty('status');

        $series->save();

        // Invalidate counts cache
        $this->invalidateCountsCache($request->user()->id);

        if ($statusChanged) {
            // Clear homepage caches so the new series appears immediately
            Cache::forget('home:featured');
            Cache::forget('home:trending');
            Cache::forget('home:latest');
            Cache::forget('home:new_releases');
        }

        return response()->json($series);
    }

    /** Publish series (status: draft → published) */
    public function publish(Request $request, Series $series)
    {
        abort_if($series->author_id !== $request->user()->id, 403);
        abort_if($series->status === 'published', 422, 'Series sudah dipublish.');

        $series->update(['status' => 'published']);

        // Invalidate counts cache
        $this->invalidateCountsCache($request->user()->id);

        // Clear homepage caches so the new series appears immediately
        Cache::forget('home:featured');
        Cache::forget('home:trending');
        Cache::forget('home:latest');
        Cache::forget('home:new_releases');

        return response()->json(['message' => 'Series berhasil dipublish! 🎉', 'series' => $series]);
    }

    /** Dashboard stats for author (cached 60s) */
    public function dashboard(Request $request)
    {
        $user = $request->user();
        $cacheKey = "author:{$user->id}:dashboard";

        $data = Cache::remember($cacheKey, 60, function () use ($user) {
            $seriesAll = Series::where('author_id', $user->id)->get();

            return [
                'stats' => [
                    'total_series'   => $seriesAll->count(),
                    'total_views'    => $seriesAll->sum('total_views'),
                    'total_likes'    => $seriesAll->sum('total_likes'),
                    'coins'          => $user->coins,
                    'author_tier'    => $user->author_tier,
                    'followers'      => $user->followers()->count(),
                ],
                'recent_series' => Series::where('author_id', $user->id)
                    ->withCount('episodes')
                    ->orderBy('updated_at', 'desc')
                    ->take(5)
                    ->get(),
            ];
        });

        return response()->json($data);
    }

    /** Delete series (soft-delete) */
    public function destroy(Request $request, Series $series)
    {
        abort_if($series->author_id !== $request->user()->id, 403);

        // Delete cover from R2 if exists
        if ($series->cover_url) {
            Storage::disk('s3')->delete($series->cover_url);
        }

        $series->delete(); // soft-delete karena ada softDeletes di migration

        // Invalidate counts cache
        $this->invalidateCountsCache($request->user()->id);

        return response()->json(['message' => 'Series berhasil dihapus']);
    }

    /** Invalidate author counts + dashboard cache */
    private function invalidateCountsCache(int $userId): void
    {
        Cache::forget("author:{$userId}:series_counts");
        Cache::forget("author:{$userId}:dashboard");
    }
}
