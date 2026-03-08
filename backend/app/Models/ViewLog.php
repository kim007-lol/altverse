<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ViewLog extends Model
{
    protected $table = 'views_log';

    protected $fillable = ['user_id', 'episode_id', 'series_id', 'viewed_date'];

    protected function casts(): array
    {
        return ['viewed_date' => 'date'];
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }
    public function episode()
    {
        return $this->belongsTo(Episode::class);
    }
    public function series()
    {
        return $this->belongsTo(Series::class);
    }
}
