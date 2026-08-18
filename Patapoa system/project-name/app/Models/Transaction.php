<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * @property int $id
 * @property int $user_id
 * @property int|null $order_id
 * @property string $type
 * @property string $status
 * @property string $amount
 * @property string $currency
 * @property string|null $payment_method
 * @property string|null $transaction_reference
 * @property string|null $description
 * @property array|null $metadata
 * @property \Illuminate\Support\Carbon|null $processed_at
 *
 * @property-read \App\Models\User $user
 * @property-read \App\Models\Order|null $order
 */
class Transaction extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'order_id',
        'type',
        'status',
        'amount',
        'currency',
        'payment_method',
        'transaction_reference',
        'description',
        'metadata',
        'processed_at',
    ];

    protected $casts = [
        'amount' => 'decimal:2',
        'metadata' => 'array',
        'processed_at' => 'datetime',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function order(): BelongsTo
    {
        return $this->belongsTo(Order::class);
    }
}
