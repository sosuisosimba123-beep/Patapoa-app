<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\MasterProduct;

class MasterProductImagesSeeder extends Seeder
{
    public function run(): void
    {
        // Using Unsplash Source URLs which are guaranteed direct image links and highly reliable for web
        $updates = [
            'Sugar' => 'https://images.unsplash.com/photo-1581447100595-3a74a558eb21?q=80&w=600&auto=format&fit=crop',
            'Milk' => 'https://images.unsplash.com/photo-1550583724-1255d1ec552d?q=80&w=600&auto=format&fit=crop',
            'Water' => 'https://images.unsplash.com/photo-1560064060-1f0124cdc931?q=80&w=600&auto=format&fit=crop',
            'Flour' => 'https://images.unsplash.com/photo-1627485204598-9445ef59ef4e?q=80&w=600&auto=format&fit=crop',
            'Soda' => 'https://images.unsplash.com/photo-1622483767028-3f66f32aef97?q=80&w=600&auto=format&fit=crop',
            'Biscuits' => 'https://images.unsplash.com/photo-1558961363-fa8fdf82db35?q=80&w=600&auto=format&fit=crop',
            'Soap' => 'https://images.unsplash.com/photo-1600857062241-98e5dba7f214?q=80&w=600&auto=format&fit=crop',
        ];

        foreach ($updates as $category => $url) {
            // Update all products that contain the category name in their tags
            MasterProduct::whereJsonContains('search_tags', $category)
                ->orWhere('name', 'like', "%$category%")
                ->update(['primary_image_url' => $url]);
        }

        // Specific Fixes for brands
        MasterProduct::where('brand', 'Kilombero')->update(['primary_image_url' => $updates['Sugar']]);
        MasterProduct::where('brand', 'ASAS')->update(['primary_image_url' => $updates['Milk']]);
        MasterProduct::where('brand', 'Azam')->where('name', 'like', '%Milk%')->update(['primary_image_url' => $updates['Milk']]);
    }
}
