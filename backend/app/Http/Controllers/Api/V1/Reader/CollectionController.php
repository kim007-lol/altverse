<?php

namespace App\Http\Controllers\Api\V1\Reader;

use App\Http\Controllers\Controller;
use App\Models\Collection;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CollectionController extends Controller
{
    /** Get user's collections */
    public function index(Request $request): JsonResponse
    {
        $collections = $request->user()
            ->collections()
            ->withCount('series')
            ->latest()
            ->get();

        return response()->json($collections);
    }

    /** Create collection */
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name'        => 'required|string|max:100',
            'description' => 'nullable|string|max:500',
            'is_public'   => 'nullable|boolean',
        ]);

        $collection = $request->user()->collections()->create($validated);

        return response()->json([
            'message'    => 'Collection berhasil dibuat',
            'collection' => $collection,
        ], 201);
    }

    /** Update collection */
    public function update(Request $request, Collection $collection): JsonResponse
    {
        if ($collection->user_id !== $request->user()->id) {
            return response()->json(['message' => 'Forbidden'], 403);
        }

        $validated = $request->validate([
            'name'        => 'sometimes|string|max:100',
            'description' => 'nullable|string|max:500',
            'is_public'   => 'nullable|boolean',
        ]);

        $collection->update($validated);

        return response()->json([
            'message'    => 'Collection berhasil diperbarui',
            'collection' => $collection->fresh(),
        ]);
    }

    /** Delete collection */
    public function destroy(Request $request, Collection $collection): JsonResponse
    {
        if ($collection->user_id !== $request->user()->id) {
            return response()->json(['message' => 'Forbidden'], 403);
        }

        $collection->delete();
        return response()->json(['message' => 'Collection berhasil dihapus']);
    }

    /** Add Series to collection */
    public function addSeries(Request $request, Collection $collection): JsonResponse
    {
        if ($collection->user_id !== $request->user()->id) {
            return response()->json(['message' => 'Forbidden'], 403);
        }

        $validated = $request->validate([
            'series_id' => 'required|exists:series,id',
        ]);

        if ($collection->series()->where('series_id', $validated['series_id'])->exists()) {
            return response()->json(['message' => 'Series sudah ada di collection'], 422);
        }

        $nextOrder = $collection->series()->max('collection_series.order') + 1;
        $collection->series()->attach($validated['series_id'], ['order' => $nextOrder]);

        return response()->json(['message' => 'Series ditambahkan ke collection']);
    }

    /** Remove Series from collection */
    public function removeSeries(Request $request, Collection $collection, int $seriesId): JsonResponse
    {
        if ($collection->user_id !== $request->user()->id) {
            return response()->json(['message' => 'Forbidden'], 403);
        }

        $collection->series()->detach($seriesId);
        return response()->json(['message' => 'Series dihapus dari collection']);
    }

    /** Get collection detail with Series */
    public function show(Request $request, Collection $collection): JsonResponse
    {
        if (!$collection->is_public && $collection->user_id !== $request->user()->id) {
            return response()->json(['message' => 'Forbidden'], 403);
        }

        $collection->load(['series' => function ($q) {
            $q->with(['author:id,name,pen_name'])
                ->withCount('episodes')
                ->orderBy('collection_series.order');
        }]);

        return response()->json($collection);
    }
}
