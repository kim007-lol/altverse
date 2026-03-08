<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Notification;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class NotificationController extends Controller
{
    /**
     * Get user's notifications filtered by role.
     * Query param: ?role=reader|author (defaults to user's active_mode)
     */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        $role = $request->query('role', $user->role ?? 'reader');

        $notifications = Notification::where('user_id', $user->id)
            ->where('target_role', $role)
            ->latest()
            ->paginate(20);

        $unreadCount = Notification::where('user_id', $user->id)
            ->where('target_role', $role)
            ->where('is_read', false)
            ->count();

        return response()->json([
            'data'         => $notifications->items(),
            'unread_count' => $unreadCount,
            'current_page' => $notifications->currentPage(),
            'last_page'    => $notifications->lastPage(),
        ]);
    }

    /** Mark single notification as read */
    public function markRead(Request $request, string $id): JsonResponse
    {
        $notif = Notification::where('user_id', $request->user()->id)->findOrFail($id);
        $notif->update(['is_read' => true]);

        return response()->json(['message' => 'Notifikasi ditandai dibaca']);
    }

    /** Mark all as read (filtered by role) */
    public function markAllRead(Request $request): JsonResponse
    {
        $user = $request->user();
        $role = $request->input('role', $user->role ?? 'reader');

        Notification::where('user_id', $user->id)
            ->where('target_role', $role)
            ->where('is_read', false)
            ->update(['is_read' => true]);

        return response()->json(['message' => 'Semua notifikasi ditandai dibaca']);
    }

    /** Get unread count (filtered by role) */
    public function unreadCount(Request $request): JsonResponse
    {
        $user = $request->user();
        $role = $request->query('role', $user->role ?? 'reader');

        $count = Notification::where('user_id', $user->id)
            ->where('target_role', $role)
            ->where('is_read', false)
            ->count();

        return response()->json(['unread_count' => $count]);
    }

    // ─── Helper: Create notification (can be called from other controllers) ───
    public static function createNotification(
        int $userId,
        string $type,
        string $targetRole,
        string $title,
        ?string $body = null,
        ?array $data = null,
    ): Notification {
        return Notification::create([
            'id'          => \Illuminate\Support\Str::uuid(),
            'user_id'     => $userId,
            'type'        => $type,
            'target_role' => $targetRole,
            'title'       => $title,
            'body'        => $body,
            'data'        => $data,
        ]);
    }
}
