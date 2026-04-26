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
     * Supports grouping for similar notifications
     */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        $role = $request->query('role', $user->role ?? 'reader');
        $grouped = $request->query('grouped', false);

        $query = Notification::where('user_id', $user->id)
            ->where('target_role', $role)
            ->latest();
            
        if ($grouped) {
            // Group similar notifications
            $notifications = $query->get()->groupBy('group_key')->map(function ($group) {
                if ($group->count() > 1) {
                    $first = $group->first();
                    return [
                        'id' => $first->id,
                        'type' => $first->type,
                        'group_key' => $first->group_key,
                        'title' => $first->title,
                        'body' => $first->body,
                        'count' => $group->count(),
                        'is_read' => $group->every(fn($n) => $n->is_read),
                        'created_at' => $first->created_at,
                        'items' => $group->take(3)->values(),
                    ];
                }
                return $group->first();
            })->values();
            
            return response()->json([
                'data' => $notifications,
                'unread_count' => Notification::where('user_id', $user->id)
                    ->where('target_role', $role)
                    ->where('is_read', false)
                    ->count(),
            ]);
        }

        $notifications = $query->paginate(20);

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
        ?string $groupKey = null,
    ): ?Notification {
        // Check user preferences
        $preference = \App\Models\NotificationPreference::where('user_id', $userId)
            ->where('notification_type', $type)
            ->first();
            
        // If preference exists and is disabled, don't create notification
        if ($preference && !$preference->enabled) {
            return null;
        }
        
        return Notification::create([
            'id'          => \Illuminate\Support\Str::uuid(),
            'user_id'     => $userId,
            'type'        => $type,
            'group_key'   => $groupKey,
            'target_role' => $targetRole,
            'title'       => $title,
            'body'        => $body,
            'data'        => $data,
        ]);
    }
    
    /**
     * Get notification preferences
     */
    public function preferences(Request $request): JsonResponse
    {
        $user = $request->user();
        
        // Get all default types
        $defaultTypes = \App\Models\NotificationPreference::getDefaultTypes();
        
        // Get user's preferences
        $userPreferences = \App\Models\NotificationPreference::where('user_id', $user->id)
            ->get()
            ->keyBy('notification_type');
            
        // Merge with defaults
        $preferences = collect($defaultTypes)->map(function ($description, $type) use ($userPreferences) {
            $pref = $userPreferences->get($type);
            return [
                'type' => $type,
                'description' => $description,
                'enabled' => $pref ? $pref->enabled : true,
                'push_enabled' => $pref ? $pref->push_enabled : true,
                'email_enabled' => $pref ? $pref->email_enabled : false,
            ];
        })->values();
        
        return response()->json(['preferences' => $preferences]);
    }
    
    /**
     * Update notification preferences
     */
    public function updatePreferences(Request $request): JsonResponse
    {
        $user = $request->user();
        
        $validated = $request->validate([
            'preferences' => 'required|array',
            'preferences.*.type' => 'required|string',
            'preferences.*.enabled' => 'required|boolean',
            'preferences.*.push_enabled' => 'boolean',
            'preferences.*.email_enabled' => 'boolean',
        ]);
        
        foreach ($validated['preferences'] as $pref) {
            \App\Models\NotificationPreference::updateOrCreate(
                [
                    'user_id' => $user->id,
                    'notification_type' => $pref['type'],
                ],
                [
                    'enabled' => $pref['enabled'],
                    'push_enabled' => $pref['push_enabled'] ?? true,
                    'email_enabled' => $pref['email_enabled'] ?? false,
                ]
            );
        }
        
        return response()->json(['message' => 'Preferensi notifikasi berhasil diperbarui']);
    }
    
    /**
     * Delete old read notifications (cleanup)
     */
    public function cleanup(Request $request): JsonResponse
    {
        $user = $request->user();
        $days = $request->input('days', 30);
        
        $deleted = Notification::where('user_id', $user->id)
            ->where('is_read', true)
            ->where('created_at', '<', now()->subDays($days))
            ->delete();
            
        return response()->json([
            'message' => "Berhasil menghapus {$deleted} notifikasi lama",
            'deleted_count' => $deleted,
        ]);
    }
}
