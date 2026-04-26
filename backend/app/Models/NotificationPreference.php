<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class NotificationPreference extends Model
{
    protected $fillable = [
        'user_id',
        'notification_type',
        'enabled',
        'push_enabled',
        'email_enabled',
    ];

    protected $casts = [
        'enabled' => 'boolean',
        'push_enabled' => 'boolean',
        'email_enabled' => 'boolean',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
    
    /**
     * Get default notification types
     */
    public static function getDefaultTypes(): array
    {
        return [
            'new_episode' => 'Episode baru dari series yang kamu ikuti',
            'new_follower' => 'Seseorang mengikuti kamu',
            'comment_reply' => 'Balasan pada komentar kamu',
            'comment_like' => 'Seseorang menyukai komentar kamu',
            'episode_like' => 'Seseorang menyukai episode kamu',
            'series_like' => 'Seseorang menyukai series kamu',
            'badge_earned' => 'Kamu mendapatkan badge baru',
            'mission_completed' => 'Kamu menyelesaikan mission',
            'tip_received' => 'Kamu menerima tip',
            'episode_unlocked' => 'Seseorang unlock episode kamu',
            'daily_reward' => 'Daily reward tersedia',
            'level_up' => 'Kamu naik level',
            'tier_upgrade' => 'Author tier kamu naik',
        ];
    }
}
