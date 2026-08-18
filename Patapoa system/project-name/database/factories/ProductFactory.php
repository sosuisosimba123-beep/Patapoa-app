<?php

namespace Database\Factories;

use App\Models\Product;
use App\Models\Merchant;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends \Illuminate\Database\Eloquent\Factories\Factory<\App\Models\Product>
 */
class ProductFactory extends Factory
{
    protected $model = Product::class;

    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'merchant_id' => Merchant::factory(),
            'name' => $this->faker->words(3, true),
            'price' => $this->faker->numberBetween(1000, 50000),
            'stock_count' => $this->faker->numberBetween(0, 100),
            'is_available' => true,
        ];
    }
}
