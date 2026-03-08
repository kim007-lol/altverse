<?php

namespace App\Http\Controllers\Api\V1\Author;

use App\Http\Controllers\Controller;
use App\Models\Episode;
use App\Models\Series;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;

class EpisodeController extends Controller
{
    /** List episodes for a series */
    public function index(Request $request, Series $series)
    {
        abort_if($series->author_id !== $request->user()->id, 403);

        $episodes = $series->episodes()
            ->withCount('pages')
            ->orderBy('episode_number')
            ->get()
            ->map(function ($ep) {
                return [
                    'id'             => $ep->id,
                    'title'          => $ep->title,
                    'episode_number' => $ep->episode_number,
                    'status'         => $ep->status,
                    'pages_count'    => $ep->pages_count,
                    'cover_url'      => $ep->cover_url,
                    'thumbnail_url'  => $ep->thumbnail_url,
                    'is_premium'     => $ep->is_premium,
                    'coin_price'     => $ep->coin_price,
                    'published_at'   => $ep->published_at,
                    'created_at'     => $ep->created_at,
                ];
            });

        return response()->json($episodes);
    }

    /** Create new episode (draft) */
    public function store(Request $request, Series $series)
    {
        abort_if($series->author_id !== $request->user()->id, 403);

        $validated = $request->validate([
            'title'      => 'sometimes|string|max:255',
            'is_premium' => 'sometimes|boolean',
            'coin_price' => 'sometimes|integer|min:0|max:10000',
        ]);

        $lastNumber = $series->episodes()->max('episode_number') ?? 0;

        $episode = Episode::create([
            'series_id'      => $series->id,
            'title'          => $validated['title'] ?? 'Episode ' . ($lastNumber + 1),
            'episode_number' => $lastNumber + 1,
            'is_premium'     => $validated['is_premium'] ?? false,
            'coin_price'     => ($validated['is_premium'] ?? false) ? ($validated['coin_price'] ?? 0) : 0,
            'status'         => 'draft',
        ]);

        // Invalidate author caches
        Cache::forget("author:{$request->user()->id}:series_counts");
        Cache::forget("author:{$request->user()->id}:dashboard");

        return response()->json($episode, 201);
    }

    /** Update episode metadata */
    public function update(Request $request, Episode $episode)
    {
        $series = $episode->series;
        abort_if($series->author_id !== $request->user()->id, 403);

        $validated = $request->validate([
            'title'        => 'sometimes|string|max:255',
            'is_premium'   => 'sometimes|boolean',
            'coin_price'   => 'sometimes|integer|min:0',
            'scheduled_at' => 'nullable|date|after:now',
        ]);

        $episode->fill($validated);

        if (isset($validated['scheduled_at'])) {
            $episode->status = 'scheduled';
        }

        $episode->save();

        return response()->json($episode);
    }

    /** Publish episode */
    public function publish(Request $request, Episode $episode)
    {
        $series = $episode->series;
        abort_if($series->author_id !== $request->user()->id, 403);

        // Preconditions
        $pagesCount = $episode->pages()->count();
        abort_if($pagesCount === 0, 422, 'Episode harus memiliki minimal 1 halaman sebelum dipublish.');

        $episode->update([
            'status'       => 'published',
            'published_at' => now(),
        ]);

        // Invalidate caches
        Cache::forget("episode:{$episode->id}");
        Cache::forget("author:{$request->user()->id}:series_counts");
        Cache::forget("author:{$request->user()->id}:dashboard");

        // TODO: broadcast(new EpisodePublished($episode));

        return response()->json([
            'message' => 'Episode berhasil dipublish! 🎉',
            'episode' => $episode,
        ]);
    }

    /** Soft delete episode */
    public function destroy(Request $request, Episode $episode)
    {
        $series = $episode->series;
        abort_if($series->author_id !== $request->user()->id, 403);

        // Delete all page images from R2
        foreach ($episode->pages as $page) {
            \Illuminate\Support\Facades\Storage::disk('s3')->delete($page->image_path);
        }

        $episode->pages()->delete();
        $episode->delete();

        // Invalidate author caches
        Cache::forget("author:{$request->user()->id}:series_counts");
        Cache::forget("author:{$request->user()->id}:dashboard");

        return response()->json(['message' => 'Episode berhasil dihapus.']);
    }
}
