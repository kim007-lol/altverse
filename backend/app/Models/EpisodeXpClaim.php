<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class EpisodeXpClaim extends Model
{
    public $timestamps = false;

    protected $fillable = ['user_id', 'episode_id', 'claimed_at'];

    protected function casts(): array
    {
        return ['claimed_at' => 'datetime'];
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function episode()
    {
        return $this->belongsTo(Episode::class);
    }
}
