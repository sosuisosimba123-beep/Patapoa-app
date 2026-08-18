<?php

namespace Database\Seeders;

use App\Models\Merchant;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class MerchantSpatialSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // Reference Point: Moshi Clock Tower
        // Lat: -3.3349, Lng: 37.3404

        $merchants = [
            [
                'store_name' => 'Moshi Central Market Vendor',
                'city' => 'Moshi',
                'latitude' => -3.3360, // Very close (~200m)
                'longitude' => 37.3410,
            ],
            [
                'store_name' => 'KCMC Area Grocery',
                'city' => 'Moshi',
                'latitude' => -3.3150, // ~4km away
                'longitude' => 37.3280,
            ],
            [
                'store_name' => 'Himo Town Store',
                'city' => 'Himo',
                'latitude' => -3.3850, // ~25km away
                'longitude' => 37.5500,
            ],
            [
                'store_name' => 'Arusha Gateway Shop',
                'city' => 'Arusha',
                'latitude' => -3.3731, // ~80km away
                'longitude' => 36.6852,
            ],
            [
                'store_name' => 'Global Simulation Store',
                'city' => 'Virtual',
                'latitude' => 0.0000,
                'longitude' => 0.0000,
            ]
        ];

        foreach ($merchants as $data) {
            $user = User::factory()->create([
                'user_type' => 'merchant',
                'name' => $data['store_name'] . ' Owner',
            ]);

            Merchant::create(array_merge($data, [
                'user_id' => $user->id,
                'address' => 'Test Address in ' . $data['city'],
                'is_verified' => true,
                'is_online' => true,
            ]));
        }
    }
}
