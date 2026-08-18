<?php

namespace App\Models;

use Illuminate\Contracts\Auth\MustVerifyEmail;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

/**
 * @property int $id
 * @property string $name
 * @property string|null $email
 * @property string $phone
 * @property \Illuminate\Support\Carbon|null $email_verified_at
 * @property \Illuminate\Support\Carbon|null $phone_verified_at
 * @property string|null $password
 * @property string $user_type
 * @property string|null $fcm_token
 * @property bool $is_active
 * @property bool $is_verified
 *
 * @property-read \App\Models\Merchant|null $merchant
 * @property-read \App\Models\DeliveryPartner|null $deliveryPartner
 * @property-read \Illuminate\Database\Eloquent\Collection|\App\Models\Address[] $addresses
 * @property-read \Illuminate\Database\Eloquent\Collection|\App\Models\Order[] $orders
 * @property-read \Illuminate\Database\Eloquent\Collection|\App\Models\Order[] $deliveredOrders
 * @property-read \App\Models\Wallet|null $wallet
 * @property-read \Illuminate\Database\Eloquent\Collection|\App\Models\Transaction[] $transactions
 * @property-read \Illuminate\Database\Eloquent\Collection|\App\Models\Notification[] $notifications
 */
class User extends Authenticatable implements MustVerifyEmail
{
    use HasFactory, Notifiable, HasApiTokens;

    protected $fillable = ['name', 'email', 'phone', 'password', 'user_type', 'fcm_token', 'is_active', 'is_verified'];
    protected $hidden = ['password', 'remember_token'];
    protected $casts = [
        'email_verified_at' => 'datetime',
        'phone_verified_at' => 'datetime',
        'password' => 'hashed',
        'is_active' => 'boolean',
        'is_verified' => 'boolean',
    ];

    public function markEmailAsVerified()
    {
        return $this->forceFill([
            'email_verified_at' => $this->freshTimestamp(),
            'is_verified' => true,
        ])->save();
    }

    public function merchant(): HasOne
    {
        return $this->hasOne(Merchant::class);
    }

    public function deliveryPartner(): HasOne
    {
        return $this->hasOne(DeliveryPartner::class);
    }

    public function addresses(): HasMany
    {
        return $this->hasMany(Address::class);
    }

    public function orders(): HasMany
    {
        return $this->hasMany(Order::class, 'customer_id');
    }

    public function deliveredOrders(): HasMany
    {
        return $this->hasMany(Order::class, 'delivery_partner_id');
    }

    public function wallet(): HasOne
    {
        return $this->hasOne(Wallet::class);
    }

    public function transactions(): HasMany
    {
        return $this->hasMany(Transaction::class);
    }

    public function notifications(): HasMany
    {
        return $this->hasMany(Notification::class);
    }

    public function isMerchant(): bool
    {
        return $this->user_type === 'merchant';
    }

    public function isDeliveryPartner(): bool
    {
        return $this->user_type === 'rider';
    }

    public function isCustomer(): bool
    {
        return $this->user_type === 'customer';
    }

    public function isAdmin(): bool
    {
        return $this->user_type === 'admin';
    }
}
