<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\MasterProduct;
use App\Models\SecondaryCategory;
use Illuminate\Support\Str;

class MasterProductSeeder extends Seeder
{
    public function run(): void
    {
        $templates = [
            ['name' => 'Milk (Maziwa)', 'sec' => 'fresh milk & yogurt', 'tags' => ['milk', 'fresh', 'dairy', 'maziwa']],
            ['name' => 'Yogurt', 'sec' => 'fresh milk & yogurt', 'tags' => ['yogurt', 'dairy']],
            ['name' => 'Eggs (Mayai)', 'sec' => 'eggs & butter', 'tags' => ['eggs', 'mayai']],

            ['name' => 'Drinking Water', 'sec' => 'water', 'tags' => ['water', 'maji', 'drink']],
            ['name' => 'Soda / Soft Drink', 'sec' => 'soda & soft drinks', 'tags' => ['soda', 'coke', 'drink', 'soft drink']],
            ['name' => 'Juice', 'sec' => 'juices', 'tags' => ['juice', 'drink']],

            ['name' => 'Sugar (Sukari)', 'sec' => 'sugar & salt and spices', 'tags' => ['sugar', 'sukari']],
            ['name' => 'Rice (Mchele)', 'sec' => 'rice & legumes', 'tags' => ['rice', 'mchele']],
            ['name' => 'Wheat Flour (Ngano)', 'sec' => 'flour & grains', 'tags' => ['flour', 'ngano', 'wheat']],
            ['name' => 'Maize Flour (Sembe/Dona)', 'sec' => 'flour & grains', 'tags' => ['flour', 'sembe', 'dona', 'maize']],

            ['name' => 'Cooking Oil (Mafuta)', 'sec' => 'cooking oil & fats', 'tags' => ['oil', 'cooking', 'mafuta']],
            ['name' => 'Salt (Chumvi)', 'sec' => 'sugar & salt and spices', 'tags' => ['salt', 'chumvi']],

            ['name' => 'Bread (Mkate)', 'sec' => 'biscuits & cookies', 'tags' => ['bread', 'mkate', 'bakery']], // Closest match in snacks

            ['name' => 'Biscuits', 'sec' => 'biscuits & cookies', 'tags' => ['biscuits', 'snacks']],
            ['name' => 'Potato Chips', 'sec' => 'crisps & cereals', 'tags' => ['chips', 'snacks']],

            ['name' => 'Laundry Detergent', 'sec' => 'detergent & soap', 'tags' => ['detergent', 'soap', 'washing']],
            ['name' => 'Dish Soap', 'sec' => 'detergent & soap', 'tags' => ['soap', 'dish']],
        ];

        foreach ($templates as $t) {
            $sec = SecondaryCategory::where('name', $t['sec'])->first();

            MasterProduct::updateOrCreate(
                ['slug' => Str::slug($t['name'])],
                [
                    'secondary_category_id' => $sec?->id,
                    'name' => $t['name'],
                    'brand' => 'Generic',
                    'primary_image_url' => '', // Purely uses 3D fallbacks
                    'search_tags' => $t['tags'],
                ]
            );
        }
    }
}
