<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

/**
 * @property int $id
 * @property int $user_id
 * @property string $store_name
 * @property string|null $shop_type
 * @property string|null $description
 * @property string|null $business_reg_no
 * @property string|null $address
 * @property string|null $latitude
 * @property string|null $longitude
 * @property mixed $location
 * @property string|null $landmark
 * @property string|null $district
 * @property string|null $city
 * @property string|null $region
 * @property string|null $commission_rate
 * @property string|null $payout_method
 * @property string|null $payout_account
 * @property bool $is_verified
 * @property bool $is_online
 * @property string $rating
 * @property int $total_orders
 * @property float|null $revenue
 *
 * @property-read \App\Models\User $user
 * @property-read \Illuminate\Database\Eloquent\Collection|\App\Models\Product[] $products
 * @property-read \App\Models\Wallet|null $wallet
 * @property-read \Illuminate\Database\Eloquent\Collection|\App\Models\OrderItem[] $orders
 *
 * @method static \Illuminate\Database\Eloquent\Builder|Merchant withinRadius($lat, $lng, $radiusKm = 15)
 * @method static \Illuminate\Database\Eloquent\Builder|Merchant withDistance($lat, $lng)
 */
class Merchant extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'store_name',
        'shop_type',
        'description',
        'business_reg_no',
        'address',
        'latitude',
        'longitude',
        'location', // Added spatial field
        'landmark',
        'district',
        'city',
        'region',
        'commission_rate',
        'payout_method',
        'payout_account',
        'is_verified',
        'is_online',
        'rating',
        'total_orders',
    ];

    protected $casts = [
        'latitude' => 'decimal:8',
        'longitude' => 'decimal:8',
        'commission_rate' => 'decimal:2',
        'rating' => 'decimal:2',
        'is_verified' => 'boolean',
        'is_online' => 'boolean',
    ];

    /**
     * Boot the model and add a saving listener to sync spatial point.
     */
    protected static function boot()
    {
        parent::boot();

        static::saving(function ($merchant) {
            if ($merchant->isDirty(['latitude', 'longitude'])) {
                $lat = $merchant->latitude;
                $lng = $merchant->longitude;

                if (\Illuminate\Support\Facades\DB::getDriverName() === 'sqlite') {
                    $merchant->location = "POINT($lng $lat)";
                } else {
                    $merchant->location = \Illuminate\Support\Facades\DB::raw("ST_PointFromText('POINT($lng $lat)')");
                }
            }
        });
    }

    /**
     * Scope for proximity search using high-performance ST_Distance_Sphere.
     * Falls back to Haversine for SQLite (tests).
     */
    public function scopeWithinRadius($query, $lat, $lng, $radiusKm = 15)
    {
        if (\Illuminate\Support\Facades\DB::getDriverName() === 'sqlite') {
            // Haversine formula for SQLite
            return $query->whereRaw(
                "(6371 * acos(cos(radians(?)) * cos(radians(latitude)) * cos(radians(longitude) - radians(?)) + sin(radians(?)) * sin(radians(latitude)))) <= ?",
                [$lat, $lng, $lat, $radiusKm]
            );
        }

        return $query->whereRaw(
            "ST_Distance_Sphere(location, ST_PointFromText(CONCAT('POINT(', ?, ' ', ?, ')'))) <= ?",
            [$lng, $lat, $radiusKm * 1000] // Distance in meters
        );
    }

    /**
     * Select distance from a point.
     * Falls back to Haversine for SQLite (tests).
     */
    public function scopeWithDistance($query, $lat, $lng)
    {
        if (\Illuminate\Support\Facades\DB::getDriverName() === 'sqlite') {
            return $query->selectRaw(
                "*, (6371 * acos(cos(radians(?)) * cos(radians(latitude)) * cos(radians(longitude) - radians(?)) + sin(radians(?)) * sin(radians(latitude)))) AS distance_km",
                [$lat, $lng, $lat]
            );
        }

        return $query->selectRaw(
            "*, ST_Distance_Sphere(location, ST_PointFromText(CONCAT('POINT(', ?, ' ', ?, ')'))) / 1000 AS distance_km",
            [$lng, $lat]
        );
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function products(): HasMany
    {
        return $this->hasMany(Product::class);
    }

    public function wallet()
    {
        return $this->hasOne(Wallet::class, 'user_id', 'user_id')->where('wallet_type', 'merchant');
    }

    public function orders(): HasMany
    {
        return $this->hasMany(OrderItem::class, 'merchant_id');
    }
}
