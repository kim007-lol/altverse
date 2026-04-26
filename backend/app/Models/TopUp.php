<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class TopUp extends Model
{
    protected $fillable = [
        'user_id',
        'order_id',
        'package_id',
        'amount_idr',
        'coins',
        'status',
        'midtrans_transaction_id',
        'payment_type',
        'paid_at',
    ];

    protected $casts = [
        'paid_at' => 'datetime',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
