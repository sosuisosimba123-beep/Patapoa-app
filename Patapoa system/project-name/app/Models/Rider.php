<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Rider extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'vehicle_type',
        'license_plate',
        'driver_license',
        'city',
        'is_online',
        'is_verified',
        'is_on_delivery',
        'current_latitude',
        'current_longitude',
        'last_location_update',
        'tier',
        'rating',
        'total_deliveries',
    ];

    protected $casts = [
        'current_latitude' => 'decimal:8',
        'current_longitude' => 'decimal:8',
        'rating' => 'decimal:2',
        'is_online' => 'boolean',
        'is_verified' => 'boolean',
        'is_on_delivery' => 'boolean',
        'last_location_update' => 'datetime',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function orders(): HasMany
    {
        return $this->hasMany(Order::class);
    }

    public function wallet()
    {
        return $this->hasOne(Wallet::class)->where('wallet_type', 'rider');
    }
}
