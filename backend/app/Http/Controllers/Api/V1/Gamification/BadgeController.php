<?php

namespace App\Http\Controllers\Api\V1\Gamification;

use App\Http\Controllers\Controller;
use App\Models\Badge;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class BadgeController extends Controller
{
    /**
     * Pin a custom badge. Unpins currently pinned custom badge and sets the new one.
     */
    public function pin(Request $request, Badge $badge): JsonResponse
    {
        $user = $request->user();

        // Ensure user actually owns this badge
        $userBadge = $user->badges()->where('badge_id', $badge->id)->first();

        if (!$userBadge) {
            return response()->json(['message' => 'Anda tidak memiliki badge ini.'], 403);
        }

        // Prevent pinning a lifetime badge manually (they are auto-pinned)
        $lifetimeKeys = ['lifetime_perak', 'lifetime_emas', 'lifetime_diamond', 'lifetime_platinum', 'lifetime_legendary'];
        if (in_array($badge->key, $lifetimeKeys)) {
            return response()->json(['message' => 'Lifetime badge sudah otomatis di-pin.'], 422);
        }

        // Only unpin NON-lifetime (custom) badges — preserve auto-pinned lifetime badges
        $lifetimeBadgeIds = Badge::whereIn('key', $lifetimeKeys)->pluck('id')->toArray();
        $customBadgeIds = $user->badges()
            ->whereNotIn('badge_id', $lifetimeBadgeIds)
            ->pluck('badge_id')
            ->toArray();

        if (!empty($customBadgeIds)) {
            $user->badges()->updateExistingPivot($customBadgeIds, ['is_pinned' => false]);
        }

        // Pin the selected custom badge
        $user->badges()->updateExistingPivot($badge->id, ['is_pinned' => true]);

        return response()->json(['message' => 'Badge berhasil di-pin!']);
    }
}
