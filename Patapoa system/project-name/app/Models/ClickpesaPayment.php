<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ClickpesaPayment extends Model
{
    use HasFactory;

    protected $fillable = [
        'reference_id',
        'external_id',
        'payment_method',
        'phone_number',
        'card_number_masked',
        'amount',
        'currency',
        'status',
        'status_detail',
        'request_payload',
        'response_payload',
        'paid_at',
    ];

    protected $casts = [
        'request_payload' => 'array',
        'response_payload' => 'array',
        'paid_at' => 'datetime',
        'amount' => 'decimal:2',
    ];

    /**
     * Get the associated platform transaction
     */
    public function transaction()
    {
        return $this->belongsTo(Transaction::class, 'reference_id', 'transaction_reference');
    }
}
