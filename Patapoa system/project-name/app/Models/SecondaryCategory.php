<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class SecondaryCategory extends Model
{
    use HasFactory;

    protected $fillable = ['primary_category_id', 'name', 'slug', 'image_url', 'is_active', 'sort_order'];

    protected $casts = [
        'is_active' => 'boolean',
    ];

    public function primaryCategory(): BelongsTo
    {
        return $this->belongsTo(PrimaryCategory::class);
    }

    public function masterProducts(): HasMany
    {
        return $this->hasMany(MasterProduct::class);
    }

    public function products(): HasMany
    {
        return $this->hasMany(Product::class);
    }
}
