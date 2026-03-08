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

    public function episode()
    {
        return $this->belongsTo(Episode::class);
    }
}
