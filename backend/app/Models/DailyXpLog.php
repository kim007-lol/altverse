<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class DailyXpLog extends Model
{
    protected $fillable = ['user_id', 'date', 'activity', 'xp_earned', 'action_count'];

    protected function casts(): array
    {
        return ['date' => 'date'];
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
