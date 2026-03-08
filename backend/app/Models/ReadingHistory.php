<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ReadingHistory extends Model
{
    protected $fillable = ['user_id', 'series_id', 'episode_id', 'last_page', 'progress', 'read_at'];

    protected function casts(): array
    {
        return ['read_at' => 'datetime', 'progress' => 'decimal:2'];
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }
    public function series()
    {
        return $this->belongsTo(Series::class);
    }
    public function episode()
    {
        return $this->belongsTo(Episode::class);
    }
}
