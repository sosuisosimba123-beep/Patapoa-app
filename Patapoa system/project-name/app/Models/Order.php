<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

/**
 * @property int $id
 * @property string|null $order_number
 * @property int $customer_id
 * @property int|null $delivery_partner_id
 * @property int $address_id
 * @property string $status
 * @property string $subtotal
 * @property string $delivery_fee
 * @property string $platform_fee
 * @property string $total
 * @property string|null $payment_method
 * @property string $payment_status
 * @property string|null $payment_reference
 * @property string|null $customer_notes
 * @property \Illuminate\Support\Carbon|null $placed_at
 * @property \Illuminate\Support\Carbon|null $confirmed_at
 * @property \Illuminate\Support\Carbon|null $assigned_at
 * @property \Illuminate\Support\Carbon|null $picked_up_at
 * @property \Illuminate\Support\Carbon|null $delivered_at
 * @property string|null $pickup_latitude
 * @property string|null $pickup_longitude
 * @property string|null $dropoff_latitude
 * @property string|null $dropoff_longitude
 * @property string|null $estimated_distance_km
 * @property string|null $actual_distance_km
 * @property int|null $estimated_duration_minutes
 * @property int|null $actual_duration_minutes
 *
 * @property-read string $display_id
 * @property-read float $total_amount
 * @property-read string|null $delivery_address
 * @property-read string|null $delivery_notes
 * @property-read \Illuminate\Support\Collection $items_list
 *
 * @property-read \App\Models\User $customer
 * @property-read \App\Models\DeliveryPartner|null $deliveryPartner
 * @property-read \App\Models\Address|null $address
 * @property-read \Illuminate\Database\Eloquent\Collection|\App\Models\OrderItem[] $orderItems
 * @property-read \Illuminate\Database\Eloquent\Collection|\App\Models\Transaction[] $transactions
 */
class Order extends Model
{
    use HasFactory;

    protected $fillable = [
        'order_number',
        'customer_id',
        'delivery_partner_id',
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

    protected $appends = ['display_id', 'total_amount', 'delivery_address', 'delivery_notes', 'items_list'];

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

    public function getDisplayIdAttribute(): string
    {
        return $this->order_number ?? '#' . str_pad((string) $this->id, 6, '0', STR_PAD_LEFT);
    }

    public function getTotalAmountAttribute(): float
    {
        return (float) $this->total;
    }

    public function getDeliveryAddressAttribute(): ?string
    {
        return $this->address ? ($this->address->address_line_1 . ', ' . $this->address->city) : null;
    }

    public function getDeliveryNotesAttribute(): ?string
    {
        return $this->customer_notes;
    }

    public function getItemsListAttribute()
    {
        return $this->orderItems->map(function ($item) {
            return [
                'id' => $item->id,
                'product_id' => $item->product_id,
                'product_name' => $item->product_name,
                'quantity' => $item->quantity,
                'unit_price' => (float) $item->unit_price,
                'subtotal' => (float) $item->subtotal,
            ];
        });
    }

    public function customer(): BelongsTo
    {
        return $this->belongsTo(User::class, 'customer_id');
    }

    public function deliveryPartner(): BelongsTo
    {
        return $this->belongsTo(DeliveryPartner::class, 'delivery_partner_id');
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
