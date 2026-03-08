<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class UserXp extends Model
{
    protected $table = 'user_xp';
    protected $primaryKey = 'user_id';
    public $incrementing = false;

    protected $fillable = ['user_id', 'total_xp', 'level'];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    /**
     * Calculate level from total XP.
     * Formula: Total_XP = 100 × (N × (N + 1) / 2)
     * Solving for N: N = floor((-1 + sqrt(1 + 8 * total_xp / 100)) / 2)
     */
    public static function calculateLevel(int $totalXp): int
    {
        if ($totalXp <= 0) return 0;
        return (int) floor((-1 + sqrt(1 + 8 * $totalXp / 100)) / 2);
    }

    /**
     * XP required to reach a specific level.
     */
    public static function xpForLevel(int $level): int
    {
        return (int) (100 * ($level * ($level + 1) / 2));
    }
}
