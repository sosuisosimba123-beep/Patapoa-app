<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class PrimaryCategory extends Model
{
    use HasFactory;

    protected $fillable = ['name', 'slug', 'image_url', 'is_active', 'sort_order'];

    protected $casts = [
        'is_active' => 'boolean',
    ];

    public function secondaryCategories(): HasMany
    {
        return $this->hasMany(SecondaryCategory::class)->orderBy('sort_order');
    }
}
