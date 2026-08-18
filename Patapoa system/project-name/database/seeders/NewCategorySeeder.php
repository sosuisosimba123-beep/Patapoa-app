<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\PrimaryCategory;
use App\Models\SecondaryCategory;
use Illuminate\Support\Str;

class NewCategorySeeder extends Seeder
{
    public function run(): void
    {
        $data = [
            'Snacks & Edibles' => [
                ['name' => 'biscuits & cookies', 'image' => 'biscuits & cookies.png'],
                ['name' => 'chocolate & sweets', 'image' => 'chocolate & sweets.png'],
                ['name' => 'crisps & cereals', 'image' => 'crisps & cereals.png'],
            ],
            'Groceries & Staples' => [
                ['name' => 'flour & grains'],
                ['name' => 'rice & legumes'],
                ['name' => 'pasta & noodles'],
                ['name' => 'sugar & salt and spices'],
                ['name' => 'cooking oil & fats', 'image' => 'cooking oil & fats.png'],
                ['name' => 'eggs & butter'],
            ],
            'Beverages' => [
                ['name' => 'soda & soft drinks'],
                ['name' => 'juices'],
                ['name' => 'tea & coffee product'],
                ['name' => 'water'],
                ['name' => 'fresh milk & yogurt'],
            ],
            'Household & Cleaning' => [
                ['name' => 'detergent & soap', 'image' => 'detergant & soap.png'],
                ['name' => 'dishwashing materials', 'image' => 'dishwashing materials.png'],
                ['name' => 'surface cleaners'],
                ['name' => 'toilet paper & tissues'],
            ],
            'Personal Care & Beauty' => [
                ['name' => 'skin care'],
                ['name' => 'hair care & makeup'],
                ['name' => 'oral care'],
                ['name' => 'baby care', 'image' => 'baby care.png'],
            ],
            'Electronics & Gadgets' => [
                ['name' => 'audio devices', 'image' => 'audio devices.png'],
                ['name' => 'chargers & cables', 'image' => 'chargers & cables.png'],
                ['name' => 'batteries & lighting', 'image' => 'batteries & lighting.png'],
            ],
            'Home Appliances & Utilities' => [
                ['name' => 'home appliances'],
            ],
        ];

        foreach ($data as $primaryName => $secondaries) {
            $primary = PrimaryCategory::create([
                'name' => $primaryName,
                'slug' => Str::slug($primaryName),
            ]);

            foreach ($secondaries as $sec) {
                SecondaryCategory::create([
                    'primary_category_id' => $primary->id,
                    'name' => $sec['name'],
                    'slug' => Str::slug($sec['name']),
                    'image_url' => $sec['image'] ?? null,
                ]);
            }
        }
    }
}
