<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class SupporterLevel extends Model
{
    protected $fillable = ['name', 'min_spend', 'weight', 'icon', 'color'];

    public function users()
    {
        return $this->hasMany(User::class, 'supporter_level_id');
    }
}
