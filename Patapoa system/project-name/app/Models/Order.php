<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Order extends Model
{
    use HasFactory;

    protected $fillable = [
        'customer_id',
        'rider_id',
        'address_id',
        'status',
        'subtotal',
        'delivery_fee',
        'platform_fee',
        'total',
        'payment_method',
        'payment_status',
        'payment_reference',
        'customer_notes',
        'placed_at',
        'confirmed_at',
        'assigned_at',
        'picked_up_at',
        'delivered_at',
        'pickup_latitude',
        'pickup_longitude',
        'dropoff_latitude',
        'dropoff_longitude',
        'estimated_distance_km',
        'actual_distance_km',
        'estimated_duration_minutes',
        'actual_duration_minutes',
    ];

    protected $appends = ['order_number', 'total_amount', 'delivery_address', 'delivery_notes', 'items'];

    protected $casts = [
        'subtotal' => 'decimal:2',
        'delivery_fee' => 'decimal:2',
        'platform_fee' => 'decimal:2',
        'total' => 'decimal:2',
        'pickup_latitude' => 'decimal:8',
        'pickup_longitude' => 'decimal:8',
        'dropoff_latitude' => 'decimal:8',
        'dropoff_longitude' => 'decimal:8',
        'estimated_distance_km' => 'decimal:2',
        'actual_distance_km' => 'decimal:2',
        'placed_at' => 'datetime',
        'confirmed_at' => 'datetime',
        'assigned_at' => 'datetime',
        'picked_up_at' => 'datetime',
        'delivered_at' => 'datetime',
    ];

    public function getOrderNumberAttribute(): string
    {
        return '#' . str_pad($this->id, 6, '0', STR_PAD_LEFT);
    }

    public function getTotalAmountAttribute(): float
    {
        return (float) $this->total;
    }

    public function getDeliveryAddressAttribute(): ?string
    {
        return $this->address ? $this->address->full_address : null;
    }

    public function getDeliveryNotesAttribute(): ?string
    {
        return $this->customer_notes;
    }

    public function getItemsAttribute()
    {
        return $this->orderItems->map(function ($item) {
            return [
                'id' => $item->id,
                'order_id' => $item->order_id,
                'product_id' => $item->product_id,
                'product_name' => $item->product_name,
                'quantity' => $item->quantity,
                'unit_price' => (float) $item->unit_price,
                'total_price' => (float) $item->subtotal,
            ];
        });
    }

    public function customer(): BelongsTo
    {
        return $this->belongsTo(User::class, 'customer_id');
    }

    public function rider(): BelongsTo
    {
        return $this->belongsTo(Rider::class);
    }

    public function address(): BelongsTo
    {
        return $this->belongsTo(Address::class);
    }

    public function orderItems(): HasMany
    {
        return $this->hasMany(OrderItem::class);
    }

    public function transactions()
    {
        return $this->hasMany(Transaction::class);
    }
}
