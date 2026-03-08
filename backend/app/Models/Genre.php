<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Genre extends Model
{
    use HasFactory;

    protected $fillable = ['name', 'slug', 'icon'];

    public function series()
    {
        return $this->belongsToMany(Series::class, 'genre_series');
    }
}
