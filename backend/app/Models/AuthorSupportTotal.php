<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class AuthorSupportTotal extends Model
{
    protected $fillable = ['author_id', 'user_id', 'total_spend'];

    public function author()
    {
        return $this->belongsTo(User::class, 'author_id');
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
