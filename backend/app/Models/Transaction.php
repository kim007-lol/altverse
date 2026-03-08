<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Transaction extends Model
{
    protected $fillable = ['user_id', 'type', 'amount', 'description', 'related_user_id', 'related_series_id'];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
    public function relatedUser()
    {
        return $this->belongsTo(User::class, 'related_user_id');
    }
    public function relatedSeries()
    {
        return $this->belongsTo(Series::class, 'related_series_id');
    }
}
