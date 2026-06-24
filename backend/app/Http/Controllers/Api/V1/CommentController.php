<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreCommentRequest;
use App\Models\Comment;
use App\Models\CommentLike;
use App\Models\Episode;
use App\Models\Notification;
use App\Models\UserXp;
use App\Services\XpService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class CommentController extends Controller
{
    /** Get comments for an episode (priority-sorted or newest) */
    public function index(Request $request, Episode $episode): JsonResponse
    {
        $sort = $request->query('sort', 'top');
        $userId = $request->user()->id;

        $query = Comment::where('episode_id', $episode->id)
            ->whereNull('parent_id')
            ->with([
                'user:id,name,pen_name,avatar_url,author_avatar_url,role,bio,author_bio,supporter_level_id,level',
                'user.supporterLevel:id,name,icon,color',
                'user.badges' => function ($q) {
                    $q->wherePivot('is_pinned', true);
                },
                'replies' => fn($q) => $q->with([
                    'user:id,name,pen_name,avatar_url,author_avatar_url,role,bio,author_bio',
                    'user.badges' => function ($qb) {
                        $qb->wherePivot('is_pinned', true);
                    }
                ])->latest(),
            ]);

        if ($sort === 'new') {
            $query->orderByDesc('created_at');
        } else {
            $query->orderByDesc('priority_score')->orderByDesc('created_at');
        }

        $comments = $query->paginate(20);

        // Add is_liked flag and human readable time for each comment
        $comments->getCollection()->transform(function ($comment) use ($userId) {
            $comment->is_liked = CommentLike::where('user_id', $userId)
                ->where('comment_id', $comment->id)
                ->where('is_active', true)
                ->exists();
            $comment->created_at_human = $comment->created_at->diffForHumans();
            $comment->reader_tier_badge = $comment->user?->supporter_level_id ? true : null;
            return $comment;
        });

        return response()->json($comments);
    }

    /**
     * Post comment with XP award + priority scoring + anti-spam.
     *
     * Anti-spam rules:
     * 1. Min body length: 10 characters (Laravel validation)
     * 2. Min 3 unique words (quality check)
     * 3. No duplicate text in same episode today
     * 4. Cooldown: min 10 seconds between comments
     * 5. Max 10 comments per day (global)
     *
     * XP: 5 XP per comment, max 50 XP/day (tracked in DB)
     */
    public function store(StoreCommentRequest $request, Episode $episode): JsonResponse
    {
        $validated = $request->validated();
        $user = $request->user();
        $body = trim($validated['body']);

        // ─── Anti-spam #1: Word diversity check ───
        $words = preg_split('/\s+/', $body);
        $uniqueWords = array_unique(array_map('mb_strtolower', $words));
        if (count($uniqueWords) < 3) {
            return response()->json([
                'message' => 'Komentar harus mengandung minimal 3 kata yang berbeda.',
            ], 422);
        }

        // ─── Anti-spam #2: Max 10 comments per day ───
        $todayCount = Comment::where('user_id', $user->id)
            ->whereDate('created_at', now()->toDateString())
            ->count();

        if ($todayCount >= 10) {
            return response()->json([
                'message' => 'Batas komentar harian tercapai (10 per hari).',
            ], 429);
        }

        // ─── Anti-spam #3: Cooldown 10 seconds ───
        $lastComment = Comment::where('user_id', $user->id)
            ->latest('created_at')
            ->first();

        if ($lastComment && $lastComment->created_at->diffInSeconds(now()) < 10) {
            return response()->json([
                'message' => 'Tunggu minimal 10 detik sebelum komentar berikutnya.',
            ], 429);
        }

        // ─── Anti-spam #4: No duplicate text in same episode today ───
        $duplicateExists = Comment::where('user_id', $user->id)
            ->where('episode_id', $episode->id)
            ->whereDate('created_at', now()->toDateString())
            ->where('body', $body)
            ->exists();

        if ($duplicateExists) {
            return response()->json([
                'message' => 'Komentar duplikat terdeteksi. Tulis komentar yang berbeda.',
            ], 422);
        }

        // Calculate priority score
        $userXp = UserXp::find($user->id);
        $level = $userXp?->level ?? 0;
        $supporterWeight = $user->supporterLevel?->weight ?? 0;
        $priorityScore = ($level * 1.5) + $supporterWeight;

        $comment = Comment::create([
            'user_id'        => $user->id,
            'episode_id'     => $episode->id,
            'parent_id'      => $validated['parent_id'] ?? null,
            'body'           => $body,
            'priority_score' => $priorityScore,
        ]);

        $comment->load([
            'user:id,name,pen_name,avatar_url,author_avatar_url,role,bio,author_bio',
            'user.badges' => function ($q) {
                $q->wherePivot('is_pinned', true);
            }
        ]);

        // Award XP immediately, dispatch mission/badge tracking to background
        XpService::award($user->id, 'comment');
        \App\Jobs\ProcessGamificationJob::dispatch($user->id, 'comment');

        // Notify author
        $series = $episode->series;
        $authorId = $series?->author_id;
        if ($authorId && $authorId !== $user->id) {
            Notification::create([
                'id'      => Str::uuid(),
                'user_id' => $authorId,
                'type'        => 'comment_reply',
                'target_role' => 'author',
                'title'   => 'Komentar Baru',
                'body'    => ($user->role === 'author' ? $user->pen_name : $user->name) . " mengomentari episode \"{$episode->title}\"",
                'data'    => [
                    'series_id'   => $series->id,
                    'episode_id'  => $episode->id,
                    'comment_id'  => $comment->id,
                    'sender_id'   => $user->id,
                ],
            ]);
        }

        return response()->json([
            'message' => 'Komentar berhasil ditambahkan',
            'comment' => $comment,
        ], 201);
    }

    /**
     * Toggle like on a comment + recalculate priority_score.
     * Uses optimistic approach: atomic increment/decrement without row locking.
     * Rate limited to max 30 likes per day per user.
     */
    public function toggleLike(Request $request, Comment $comment): JsonResponse
    {
        $user = $request->user();

        // Find existing record (active or inactive)
        $existingLike = CommentLike::where('user_id', $user->id)
            ->where('comment_id', $comment->id)
            ->first();

        if ($existingLike && $existingLike->is_active) {
            // ── Unlike ──
            $existingLike->update(['is_active' => false]);
            $comment->decrement('likes_count');
            if ($comment->fresh()->likes_count < 0) {
                $comment->update(['likes_count' => 0]);
            }

            return response()->json(['liked' => false, 'likes_count' => max(0, $comment->fresh()->likes_count)]);
        }

        // ── Like (new or re-activate) ──

        // Rate limit: max 30 likes per day per user
        $todayLikeCount = CommentLike::where('user_id', $user->id)
            ->where('is_active', true)
            ->whereDate('created_at', now()->toDateString())
            ->count();

        if ($todayLikeCount >= 30) {
            return response()->json(['message' => 'Batas like harian tercapai (30 per hari)'], 429);
        }

        if ($existingLike) {
            $existingLike->update(['is_active' => true]);
        } else {
            CommentLike::create([
                'user_id'    => $user->id,
                'comment_id' => $comment->id,
                'xp_awarded' => ($comment->user_id !== $user->id),
                'is_active'  => true,
            ]);
        }

        $comment->increment('likes_count');
        $comment->refresh();

        // Recalculate priority score
        $commentXp = UserXp::find($comment->user_id);
        $commentLevel = $commentXp->level ?? 0;
        $commentWeight = $comment->user?->supporterLevel?->weight ?? 0;

        $comment->priority_score = ($comment->likes_count * 2)
            + ($commentLevel * 1.5)
            + $commentWeight;
        $comment->save();

        return response()->json(['liked' => true, 'likes_count' => $comment->likes_count]);
    }

    /** Delete own comment */
    public function destroy(Request $request, Comment $comment): JsonResponse
    {
        if ($comment->user_id !== $request->user()->id) {
            return response()->json(['message' => 'Forbidden'], 403);
        }

        // Cascade: delete associated likes to prevent orphaned records
        \Illuminate\Support\Facades\DB::table('comment_likes')->where('comment_id', $comment->id)->delete();

        $comment->delete();
        return response()->json(['message' => 'Komentar berhasil dihapus']);
    }

    public function userComments(Request $request): JsonResponse
    {
        $userId = $request->user()->id;

        $comments = Comment::where('user_id', $userId)
            ->with([
                'episode' => function ($q) {
                    $q->select('id', 'series_id', 'title', 'episode_number', 'thumbnail_url')
                        ->with('series:id,title');
                }
            ])
            ->latest()
            ->paginate(20);

        return response()->json($comments);
    }
}
