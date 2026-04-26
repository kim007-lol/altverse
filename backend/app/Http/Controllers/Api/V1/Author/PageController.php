<?php

namespace App\Http\Controllers\Api\V1\Author;

use App\Http\Controllers\Controller;
use App\Http\Requests\GenerateSignedUrlRequest;
use App\Http\Requests\StorePageRequest;
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
     * Get the underlying S3 client from the Storage disk.
     */
    private function getS3Client(): \Aws\S3\S3Client
    {
        // Create S3 client directly from config
        return new \Aws\S3\S3Client([
            'version' => 'latest',
            'region' => config('filesystems.disks.s3.region'),
            'endpoint' => config('filesystems.disks.s3.endpoint'),
            'use_path_style_endpoint' => config('filesystems.disks.s3.use_path_style_endpoint'),
            'credentials' => [
                'key' => config('filesystems.disks.s3.key'),
                'secret' => config('filesystems.disks.s3.secret'),
            ],
        ]);
    }

    /**
     * Generate presigned URL for direct upload to R2/S3.
     * Flutter uploads directly to R2 without going through Laravel.
     */
    public function signedUrl(GenerateSignedUrlRequest $request)
    {
        $validated = $request->validated();

        // Sanitize filename to prevent path traversal
        $safeFilename = preg_replace('/[^a-zA-Z0-9._-]/', '', basename($validated['filename']));

        // Route audio files to a separate directory
        $isAudio = in_array($validated['type'], ['audio/mpeg', 'audio/mp3', 'audio/mpeg3']);
        $prefix = $isAudio ? 'episodes/music/' : 'episodes/pages/';
        $path = $prefix . uniqid() . '_' . $safeFilename;

        $client = $this->getS3Client();
        $bucket = config('filesystems.disks.s3.bucket');

        // Generate presigned PUT URL (5 minutes)
        $command = $client->getCommand('PutObject', [
            'Bucket' => $bucket,
            'Key'    => $path,
            'ContentType' => $validated['type'],
        ]);

        $presignedRequest = $client->createPresignedRequest($command, '+5 minutes');
        $signedUrl = (string) $presignedRequest->getUri();

        // Generate public URL using AWS_URL (R2 public domain)
        $publicUrl = rtrim(config('filesystems.disks.s3.url'), '/') . '/' . $path;

        return response()->json([
            'upload_url' => $signedUrl,
            'path'       => $path,
            'public_url' => $publicUrl,
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
    public function store(StorePageRequest $request, Episode $episode)
    {
        $validated = $request->validated();

        // Guardrail: max 100 pages per episode
        abort_if($episode->pages()->count() >= 100, 422, 'Maksimal 100 halaman per episode.');

        $nextOrder = ($episode->pages()->max('page_order') ?? 0) + 1;

        $page = Page::create([
            'episode_id' => $episode->id,
            'image_path' => $validated['image_path'],
            'page_order' => $nextOrder,
            'width'      => $validated['width'] ?? null,
            'height'     => $validated['height'] ?? null,
            'file_size'  => $validated['file_size'] ?? null,
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
