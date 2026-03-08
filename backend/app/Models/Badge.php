<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Badge extends Model
{
    protected $fillable = ['key', 'name', 'description', 'icon_url', 'category', 'condition_type', 'condition_value', 'color'];

    public function users()
    {
        return $this->belongsToMany(User::class, 'badge_user')->withPivot('earned_at');
    }
}
