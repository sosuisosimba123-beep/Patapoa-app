<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

/**
 * @property int $id
 * @property int $merchant_id
 * @property int|null $secondary_category_id
 * @property int|null $master_product_id
 * @property string|null $name
 * @property string|null $brand
 * @property string|null $unit
 * @property string|null $description
 * @property array|null $images
 * @property string $price
 * @property string|null $compare_price
 * @property int $stock_count
 * @property bool $is_available
 * @property bool $is_featured
 * @property bool $is_custom
 * @property array|null $attributes
 * @property string $rating
 * @property int $total_reviews
 * @property int $total_sales
 *
 * @property-read string|null $image
 * @property-read int $stock_quantity
 * @property-read string $display_name
 * @property-read string|null $display_image
 * @property-read string $full_name
 *
 * @property-read \App\Models\Merchant $merchant
 * @property-read \App\Models\MasterProduct|null $masterProduct
 * @property-read \Illuminate\Database\Eloquent\Collection|\App\Models\OrderItem[] $orderItems
 */
class Product extends Model
{
    use HasFactory;

    protected $fillable = [
        'merchant_id',
        'secondary_category_id',
        'master_product_id',
        'name',
        'brand',
        'unit',
        'description',
        'images',
        'price',
        'compare_price',
        'stock_count',
        'is_available',
        'is_featured',
        'is_custom',
        'attributes',
        'rating',
        'total_reviews',
        'total_sales',
    ];

    protected $appends = ['image', 'stock_quantity', 'display_name', 'display_image', 'full_name', 'category_slug'];

    protected $casts = [
        'price' => 'decimal:2',
        'compare_price' => 'decimal:2',
        'images' => 'array',
        'attributes' => 'array',
        'rating' => 'decimal:2',
        'is_available' => 'boolean',
        'is_featured' => 'boolean',
    ];

    public function getDisplayNameAttribute(): string
    {
        return $this->masterProduct?->name ?? $this->name ?? 'Product';
    }

    public function getFullNameAttribute(): string
    {
        $name = $this->display_name;
        if ($this->brand) $name = "{$this->brand} $name";
        if ($this->unit) $name = "$name ({$this->unit})";
        return $name;
    }

    public function getDisplayImageAttribute(): ?string
    {
        $image = $this->image ?? $this->masterProduct?->primary_image_url;
        return $image ?? 'https://via.placeholder.com/300?text=No+Image';
    }

    public function getImageAttribute(): ?string
    {
        // If linked to master product, use master image if local is null
        if ($this->master_product_id && $this->masterProduct) {
            $images = $this->images;
            if (empty($images)) {
                return $this->masterProduct->primary_image_url;
            }
        }

        $images = $this->images;
        return (is_array($images) && count($images) > 0) ? $images[0] : null;
    }

    public function getCategorySlugAttribute(): string
    {
        return $this->secondaryCategory?->slug ?? $this->masterProduct?->secondaryCategory?->slug ?? 'other';
    }

    public function getStockQuantityAttribute(): int
    {
        return $this->stock_count;
    }

    public function merchant(): BelongsTo
    {
        return $this->belongsTo(Merchant::class);
    }

    public function secondaryCategory(): BelongsTo
    {
        return $this->belongsTo(SecondaryCategory::class);
    }

    public function masterProduct(): BelongsTo
    {
        return $this->belongsTo(MasterProduct::class, 'master_product_id');
    }

    public function orderItems(): HasMany
    {
        return $this->hasMany(OrderItem::class);
    }
}
