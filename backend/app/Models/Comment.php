<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Comment extends Model
{
    use SoftDeletes;

    protected $fillable = ['user_id', 'episode_id', 'parent_id', 'body', 'likes_count', 'priority_score'];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
    public function episode()
    {
        return $this->belongsTo(Episode::class);
    }
    public function parent()
    {
        return $this->belongsTo(Comment::class, 'parent_id');
    }
    public function replies()
    {
        return $this->hasMany(Comment::class, 'parent_id');
    }
}
