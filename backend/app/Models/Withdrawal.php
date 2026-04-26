<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Withdrawal extends Model
{
    protected $fillable = [
        'user_id',
        'amount_coins',
        'amount_idr',
        'status',
        'bank_name',
        'bank_account_number',
        'bank_account_name',
        'admin_notes',
        'processed_at',
    ];

    protected $casts = [
        'processed_at' => 'datetime',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
