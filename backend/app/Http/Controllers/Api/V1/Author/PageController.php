<?php

namespace App\Http\Controllers\Api\V1\Author;

use App\Http\Controllers\Controller;
use App\Jobs\DeleteOldImageJob;
use App\Models\Episode;
use App\Models\Page;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;

class PageController extends Controller
{
    /**
     * Generate presigned URL for direct upload to R2/S3.
     * Flutter akan upload langsung ke R2 tanpa melalui server Laravel.
     */
    public function signedUrl(Request $request)
    {
        $request->validate([
            'filename' => 'required|string|max:255',
            'type'     => 'required|string|in:image/jpeg,image/png,image/webp,image/gif',
        ]);

        // Sanitize filename to prevent path traversal
        $safeFilename = preg_replace('/[^a-zA-Z0-9._-]/', '', basename($request->filename));
        $path = 'episodes/pages/' . uniqid() . '_' . $safeFilename;

        // Generate presigned PUT URL (5 minutes)
        $command = Storage::disk('s3')->getClient()->getCommand('PutObject', [
            'Bucket' => config('filesystems.disks.s3.bucket'),
            'Key'    => $path,
            'ContentType' => $request->type,
        ]);

        $signedUrl = (string) Storage::disk('s3')
            ->getClient()
            ->createPresignedRequest($command, '+5 minutes')
            ->getUri();

        return response()->json([
            'upload_url' => $signedUrl,
            'path'       => $path,
            'public_url' => config('filesystems.disks.s3.url') . '/' . $path,
        ]);
    }

    /**
     * Get all pages for an episode.
     * GET /api/v1/author/episodes/{episode}/pages
     */
    public function index(Request $request, Episode $episode)
    {
        $series = $episode->series;
        abort_if($series->author_id !== $request->user()->id, 403);

        $pages = $episode->pages()->orderBy('page_order')->get();
        return response()->json($pages);
    }

    /**
     * Save page metadata after Flutter has uploaded the image to R2.
     * POST /api/v1/author/episodes/{episode}/pages
     */
    public function store(Request $request, Episode $episode)
    {
        $series = $episode->series;
        abort_if($series->author_id !== $request->user()->id, 403);

        $request->validate([
            'image_path' => 'required|string',
            'width'      => 'nullable|integer',
            'height'     => 'nullable|integer',
            'file_size'  => 'nullable|integer',
        ]);

        // Guardrail: max 100 pages per episode
        abort_if($episode->pages()->count() >= 100, 422, 'Maksimal 100 halaman per episode.');

        $nextOrder = ($episode->pages()->max('page_order') ?? 0) + 1;

        $page = Page::create([
            'episode_id' => $episode->id,
            'image_path' => $request->image_path,
            'page_order' => $nextOrder,
            'width'      => $request->width,
            'height'     => $request->height,
            'file_size'  => $request->file_size,
        ]);

        // Invalidate cache
        Cache::forget("episode:{$episode->id}");

        return response()->json([
            'message' => 'Halaman berhasil ditambahkan.',
            'page'    => $page,
        ], 201);
    }

    /**
     * Replace image of a page.
     * PUT /api/v1/author/pages/{page}
     */
    public function replace(Request $request, Page $page)
    {
        $series = $page->episode->series;
        abort_if($series->author_id !== $request->user()->id, 403);

        $request->validate([
            'image_path' => 'required|string',
        ]);

        $oldPath = $page->image_path;

        $page->update([
            'image_path' => $request->image_path,
            'width'      => $request->width,
            'height'     => $request->height,
            'file_size'  => $request->file_size,
        ]);

        // Async delete old image dari R2
        DeleteOldImageJob::dispatch($oldPath);

        // Invalidate cache
        Cache::forget("episode:{$page->episode_id}");

        return response()->json(['message' => 'Halaman berhasil diupdate.', 'page' => $page]);
    }

    /**
     * Reorder pages within an episode.
     * PATCH /api/v1/author/episodes/{episode}/reorder
     */
    public function reorder(Request $request, Episode $episode)
    {
        $series = $episode->series;
        abort_if($series->author_id !== $request->user()->id, 403);

        $request->validate([
            'pages'          => 'required|array',
            'pages.*.id'     => 'required|integer|exists:pages,id',
            'pages.*.order'  => 'required|integer|min:1',
        ]);

        DB::transaction(function () use ($request, $episode) {
            foreach ($request->pages as $p) {
                // Security: scope page to episode to prevent cross-episode IDOR
                Page::where('id', $p['id'])
                    ->where('episode_id', $episode->id)
                    ->update(['page_order' => $p['order']]);
            }
        });

        Cache::forget("episode:{$episode->id}");

        return response()->json(['message' => 'Urutan halaman berhasil dirubah.']);
    }

    /**
     * Delete a page.
     * DELETE /api/v1/author/pages/{page}
     */
    public function destroy(Request $request, Page $page)
    {
        $series = $page->episode->series;
        abort_if($series->author_id !== $request->user()->id, 403);

        $episodeId = $page->episode_id;
        $order = $page->page_order;
        $imagePath = $page->image_path;

        DB::transaction(function () use ($page, $episodeId, $order) {
            $page->delete();

            // Reorder remaining pages
            Page::where('episode_id', $episodeId)
                ->where('page_order', '>', $order)
                ->decrement('page_order');
        });

        // Async delete image dari R2
        DeleteOldImageJob::dispatch($imagePath);

        Cache::forget("episode:{$episodeId}");

        return response()->json(['message' => 'Halaman berhasil dihapus.']);
    }
}
