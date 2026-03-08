<?php

namespace App\Http\Controllers\Api\V1\Reader;

use App\Http\Controllers\Controller;
use App\Models\Series;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class BookmarkController extends Controller
{
    /** Get user's bookmarks */
    public function index(Request $request): JsonResponse
    {
        $bookmarks = $request->user()
            ->bookmarks()
            ->with(['author:id,name,pen_name,avatar_url'])
            ->withCount('episodes')
            ->latest('bookmarks.created_at')
            ->paginate(20);

        return response()->json($bookmarks);
    }

    /** Toggle bookmark (add/remove) */
    public function toggle(Request $request, Series $series): JsonResponse
    {
        $user = $request->user();

        if ($user->bookmarks()->where('series_id', $series->id)->exists()) {
            $user->bookmarks()->detach($series->id);
            return response()->json(['message' => 'Bookmark dihapus', 'bookmarked' => false]);
        }

        $user->bookmarks()->attach($series->id);
        return response()->json(['message' => 'Bookmark ditambahkan', 'bookmarked' => true]);
    }

    /** Check if Series is bookmarked */
    public function check(Request $request, Series $series): JsonResponse
    {
        $bookmarked = $request->user()->bookmarks()->where('series_id', $series->id)->exists();
        return response()->json(['bookmarked' => $bookmarked]);
    }
}
