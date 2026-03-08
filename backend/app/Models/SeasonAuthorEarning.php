<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class SeasonAuthorEarning extends Model
{
    protected $table = 'season_author_earning';

    protected $fillable = ['author_id', 'season_id', 'total_earned', 'rank'];

    public function author()
    {
        return $this->belongsTo(User::class, 'author_id');
    }

    public function season()
    {
        return $this->belongsTo(Season::class);
    }
}
