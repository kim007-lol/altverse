<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class UserMission extends Model
{
    protected $fillable = [
        'user_id',
        'mission_id',
        'progress',
        'completed_at',
        'claimed_at',
    ];

    protected function casts(): array
    {
        return [
            'completed_at' => 'datetime',
            'claimed_at' => 'datetime',
        ];
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function mission()
    {
        return $this->belongsTo(Mission::class);
    }
}
