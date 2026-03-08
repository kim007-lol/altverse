<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class CommentLike extends Model
{
    public $timestamps = false;

    protected $fillable = ['user_id', 'comment_id', 'xp_awarded', 'is_active'];

    protected $casts = [
        'created_at'  => 'datetime',
        'xp_awarded'  => 'boolean',
        'is_active'   => 'boolean',
    ];

    /** Scope: only active (not unliked) likes */
    public function scopeActive($query)
    {
        return $query->where('is_active', true);
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function comment()
    {
        return $this->belongsTo(Comment::class);
    }
}
