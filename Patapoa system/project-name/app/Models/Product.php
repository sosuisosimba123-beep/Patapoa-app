<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Product extends Model
{
    use HasFactory;

    protected $fillable = [
        'merchant_id',
        'category_id',
        'name',
        'description',
        'images',
        'price',
        'compare_price',
        'stock_count',
        'is_available',
        'is_featured',
        'attributes',
        'rating',
        'total_reviews',
        'total_sales',
    ];

    protected $appends = ['image', 'stock_quantity'];

    protected $casts = [
        'price' => 'decimal:2',
        'compare_price' => 'decimal:2',
        'images' => 'array',
        'attributes' => 'array',
        'rating' => 'decimal:2',
        'is_available' => 'boolean',
        'is_featured' => 'boolean',
    ];

    public function getImageAttribute(): ?string
    {
        $images = $this->images;
        return (is_array($images) && count($images) > 0) ? $images[0] : null;
    }

    public function getStockQuantityAttribute(): int
    {
        return $this->stock_count;
    }

    public function merchant(): BelongsTo
    {
        return $this->belongsTo(Merchant::class);
    }

    public function category(): BelongsTo
    {
        return $this->belongsTo(Category::class);
    }

    public function orderItems(): HasMany
    {
        return $this->hasMany(OrderItem::class);
    }
}
