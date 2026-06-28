<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Category;

class CategorySeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $categories = [
            [
                'name' => 'Electronics',
                'slug' => 'electronics',
                'description' => 'Mobile phones, laptops, accessories and more',
                'icon' => 'electronics',
                'sort_order' => 1,
            ],
            [
                'name' => 'Groceries',
                'slug' => 'groceries',
                'description' => 'Fresh food, vegetables, fruits and household items',
                'icon' => 'groceries',
                'sort_order' => 2,
            ],
            [
                'name' => 'Fashion',
                'slug' => 'fashion',
                'description' => 'Clothing, shoes, accessories and fashion items',
                'icon' => 'fashion',
                'sort_order' => 3,
            ],
            [
                'name' => 'Home & Living',
                'slug' => 'home-living',
                'description' => 'Furniture, decor, kitchen and home appliances',
                'icon' => 'home',
                'sort_order' => 4,
            ],
            [
                'name' => 'Health & Beauty',
                'slug' => 'health-beauty',
                'description' => 'Skincare, cosmetics, health products and supplements',
                'icon' => 'health',
                'sort_order' => 5,
            ],
            [
                'name' => 'Sports & Outdoors',
                'slug' => 'sports-outdoors',
                'description' => 'Sports equipment, outdoor gear and fitness items',
                'icon' => 'sports',
                'sort_order' => 6,
            ],
            [
                'name' => 'Books & Stationery',
                'slug' => 'books-stationery',
                'description' => 'Books, notebooks, pens and office supplies',
                'icon' => 'books',
                'sort_order' => 7,
            ],
            [
                'name' => 'Hardware',
                'slug' => 'hardware',
                'description' => 'Tools, construction materials and hardware supplies',
                'icon' => 'hardware',
                'sort_order' => 8,
            ],
        ];

        foreach ($categories as $category) {
            Category::create($category);
        }
    }
}
