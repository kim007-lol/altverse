<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Series extends Model
{
    use HasFactory, SoftDeletes;

    // Menentukan nama tabel yang baru (karena aslinya 'aus')
    // Setelah migration rename jalan, defaultnya akan ke 'series' anyway.

    protected $fillable = [
        'author_id',
        'title',
        'slug',
        'synopsis',
        'genre',
        'age_rating',
        'cover_url',
        'source_url',
        'status', // 'draft', 'published', 'archived'
        'is_premium',
        'total_views',
        'total_likes',
    ];

    public function getCoverUrlAttribute($value)
    {
        if (!$value) return null;
        if (str_starts_with($value, 'http')) return $value;
        try {
            return \Illuminate\Support\Facades\Storage::disk('s3')->temporaryUrl($value, now()->addMinutes(60));
        } catch (\Exception $e) {
            return url("api/v1/public/images/" . ltrim($value, '/'));
        }
    }

    public function author()
    {
        return $this->belongsTo(User::class, 'author_id');
    }

    public function episodes()
    {
        return $this->hasMany(Episode::class);
    }

    // Relationships ke Reader feature tables (diasumsikan sudah direname via migration FK)
    public function bookmarks()
    {
        return $this->hasMany(Bookmark::class);
    }

    public function likes()
    {
        return $this->hasMany(Like::class);
    }
}
