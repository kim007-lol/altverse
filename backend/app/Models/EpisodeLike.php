<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class EpisodeLike extends Model
{
    protected $fillable = ['user_id', 'episode_id', 'is_active'];

    protected $casts = [
        'is_active' => 'boolean',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function episode()
    {
        return $this->belongsTo(Episode::class);
    }
}
