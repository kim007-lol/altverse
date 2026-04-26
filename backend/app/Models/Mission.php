<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Mission extends Model
{
    protected $fillable = [
        'code',
        'name',
        'description',
        'type', // 'daily', 'weekly', 'once'
        'xp_reward',
        'coin_reward',
        'target_count',
        'is_active',
    ];

    protected function casts(): array
    {
        return [
            'is_active' => 'boolean',
        ];
    }

    /**
     * Users who have this mission (with progress tracking)
     */
    public function users()
    {
        return $this->belongsToMany(User::class, 'user_missions')
            ->withPivot('progress', 'completed_at', 'claimed_at')
            ->withTimestamps();
    }

    /**
     * Check if mission is daily
     */
    public function isDaily(): bool
    {
        return $this->type === 'daily';
    }

    /**
     * Check if mission is weekly
     */
    public function isWeekly(): bool
    {
        return $this->type === 'weekly';
    }

    /**
     * Check if mission is one-time
     */
    public function isOnce(): bool
    {
        return $this->type === 'once';
    }

    /**
     * Scope for active missions
     */
    public function scopeActive($query)
    {
        return $query->where('is_active', true);
    }

    /**
     * Scope for daily missions
     */
    public function scopeDaily($query)
    {
        return $query->where('type', 'daily');
    }

    /**
     * Scope for weekly missions
     */
    public function scopeWeekly($query)
    {
        return $query->where('type', 'weekly');
    }

    /**
     * Scope for one-time missions
     */
    public function scopeOnce($query)
    {
        return $query->where('type', 'once');
    }
}
