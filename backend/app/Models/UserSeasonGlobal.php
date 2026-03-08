<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class UserSeasonGlobal extends Model
{
    protected $table = 'user_season_global';

    protected $fillable = ['user_id', 'season_id', 'xp', 'rank'];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function season()
    {
        return $this->belongsTo(Season::class);
    }
}
