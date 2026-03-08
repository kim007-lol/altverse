<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Episode extends Model
{
    protected $fillable = [
        'series_id',
        'title',
        'episode_number',
        'cover_url',
        'thumbnail_url',
        'is_premium',
        'coin_price',
        'view_count',
        'like_count',
        'status', // 'draft', 'scheduled', 'published'
        'scheduled_at',
        'published_at',
    ];

    protected function casts(): array
    {
        return [
            'is_premium' => 'boolean',
            'scheduled_at' => 'datetime',
            'published_at' => 'datetime',
        ];
    }

    public function series()
    {
        return $this->belongsTo(Series::class);
    }

    public function pages()
    {
        return $this->hasMany(Page::class);
    }

    public function comments()
    {
        return $this->hasMany(Comment::class);
    }

    public function unlockedByUsers()
    {
        return $this->belongsToMany(User::class, 'user_episode_unlocks')
            ->withPivot('unlock_type')
            ->withTimestamps();
    }
}
