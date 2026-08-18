<?php

namespace Database\Factories;

use App\Models\DeliveryPartner;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends \Illuminate\Database\Eloquent\Factories\Factory<\App\Models\DeliveryPartner>
 */
class DeliveryPartnerFactory extends Factory
{
    protected $model = DeliveryPartner::class;

    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'user_id' => User::factory(),
            'vehicle_type' => 'motorcycle',
            'license_plate' => $this->faker->bothify('MC ####'),
            'city' => 'Moshi',
            'is_online' => true,
            'is_verified' => true,
            'is_on_delivery' => false,
            'current_latitude' => $this->faker->latitude(),
            'current_longitude' => $this->faker->longitude(),
            'rating' => 5.0,
        ];
    }
}
