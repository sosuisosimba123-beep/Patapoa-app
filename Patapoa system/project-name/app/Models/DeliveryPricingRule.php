<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class DeliveryPricingRule extends Model
{
    use HasFactory;

    protected $fillable = [
        'zone_name',
        'base_fee',
        'per_km_fee',
        'max_distance',
        'min_basket_value_for_free_delivery',
        'surge_multiplier',
        'is_active',
    ];

    protected $casts = [
        'base_fee' => 'decimal:2',
        'per_km_fee' => 'decimal:2',
        'max_distance' => 'decimal:2',
        'min_basket_value_for_free_delivery' => 'decimal:2',
        'surge_multiplier' => 'decimal:2',
        'is_active' => 'boolean',
    ];
}
