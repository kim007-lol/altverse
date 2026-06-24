<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Page extends Model
{
    protected $fillable = [
        'episode_id',
        'image_path',
        'page_order',
        'width',
        'height',
        'file_size'
    ];

    public function getImagePathAttribute($value)
    {
        if (!$value) return null;
        if (str_starts_with($value, 'http')) return $value;
        try {
            return \Illuminate\Support\Facades\Storage::disk('s3')->temporaryUrl($value, now()->addMinutes(60));
        } catch (\Exception $e) {
            return url("api/v1/public/images/" . ltrim($value, '/'));
        }
    }

    public function episode()
    {
        return $this->belongsTo(Episode::class);
    }
}
