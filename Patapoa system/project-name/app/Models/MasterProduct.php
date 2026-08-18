<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

/**
 * @property int $id
 * @property int|null $secondary_category_id
 * @property string $name
 * @property string|null $brand
 * @property string|null $barcode
 * @property string|null $unit
 * @property string|null $description
 * @property string|null $primary_image_url
 * @property string|null $backup_image_url
 * @property string $slug
 * @property array|null $search_tags
 *
 * @property-read \Illuminate\Database\Eloquent\Collection|\App\Models\Product[] $listings
 */
class MasterProduct extends Model
{
    use HasFactory;

    protected $fillable = [
        'secondary_category_id',
        'name',
        'brand',
        'barcode',
        'unit',
        'description',
        'primary_image_url',
        'backup_image_url',
        'slug',
        'search_tags',
    ];

    protected $casts = [
        'search_tags' => 'json',
    ];

    protected $appends = ['category_slug'];

    public function getCategorySlugAttribute(): string
    {
        return $this->secondaryCategory?->slug ?? 'other';
    }

    public function secondaryCategory(): BelongsTo
    {
        return $this->belongsTo(SecondaryCategory::class);
    }

    public function listings(): HasMany
    {
        return $this->hasMany(Product::class, 'master_product_id');
    }
}
