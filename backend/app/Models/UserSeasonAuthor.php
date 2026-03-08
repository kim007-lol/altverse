<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class UserSeasonAuthor extends Model
{
    protected $table = 'user_season_author';

    protected $fillable = ['user_id', 'author_id', 'season_id', 'xp', 'rank'];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function author()
    {
        return $this->belongsTo(User::class, 'author_id');
    }

    public function season()
    {
        return $this->belongsTo(Season::class);
    }
}
