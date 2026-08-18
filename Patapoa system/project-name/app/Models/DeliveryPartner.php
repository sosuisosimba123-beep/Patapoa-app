<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

/**
 * @property int $id
 * @property int $user_id
 * @property string|null $vehicle_type
 * @property string|null $license_plate
 * @property string|null $driver_license
 * @property string|null $city
 * @property bool $is_online
 * @property bool $is_verified
 * @property bool $is_on_delivery
 * @property string|null $current_latitude
 * @property string|null $current_longitude
 * @property mixed $location
 * @property \Illuminate\Support\Carbon|null $last_location_update
 * @property string|null $tier
 * @property string $rating
 * @property int $total_deliveries
 *
 * @property-read \App\Models\User $user
 * @property-read \Illuminate\Database\Eloquent\Collection|\App\Models\Order[] $orders
 * @property-read \App\Models\Wallet|null $wallet
 */
class DeliveryPartner extends Model
{
    use HasFactory;

    protected $table = 'delivery_partners';

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
        'location', // Added spatial field
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

    /**
     * Boot the model and add a saving listener to sync spatial point.
     */
    protected static function boot()
    {
        parent::boot();

        static::saving(function ($partner) {
            if ($partner->isDirty(['current_latitude', 'current_longitude'])) {
                $lat = $partner->current_latitude;
                $lng = $partner->current_longitude;

                if (\Illuminate\Support\Facades\DB::getDriverName() === 'sqlite') {
                    $partner->location = "POINT($lng $lat)";
                } else {
                    $partner->location = \Illuminate\Support\Facades\DB::raw("ST_PointFromText('POINT($lng $lat)')");
                }
            }
        });
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function orders(): HasMany
    {
        return $this->hasMany(Order::class, 'delivery_partner_id');
    }

    public function wallet()
    {
        return $this->hasOne(Wallet::class, 'user_id', 'user_id')->where('wallet_type', 'rider');
    }
}
