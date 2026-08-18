<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Product;
use App\Models\Merchant;
use App\Models\User;
use App\Models\MasterProduct;
use Illuminate\Support\Facades\Hash;

class DemoDataSeeder extends Seeder
{
    public function run(): void
    {
        // 1. Create a Fake Merchant User (For Testing)
        $merchantUser = User::updateOrCreate(
            ['phone' => '0700000000'],
            [
                'name' => 'Demo Supermarket Owner',
                'email' => 'demo_merchant@patapoa.com',
                'password' => Hash::make('password'),
                'user_type' => 'merchant',
                'is_active' => true,
                'is_verified' => true,
                'phone_verified_at' => now(),
            ]
        );

        // 2. Create Merchant Profile
        $merchant = Merchant::updateOrCreate(
            ['user_id' => $merchantUser->id],
            [
                'store_name' => 'Patapoa Demo Store (Moshi)',
                'address' => 'Moshi Town Center',
                'latitude' => -3.3488,
                'longitude' => 37.3400,
                'city' => 'Moshi',
                'is_verified' => true,
                'is_online' => true,
                'rating' => 5.0,
            ]
        );

        // 3. Create a Fake Rider
        $riderUser = User::updateOrCreate(
            ['phone' => '0711111111'],
            [
                'name' => 'Demo Rider',
                'email' => 'demo_rider@patapoa.com',
                'password' => Hash::make('password'),
                'user_type' => 'rider',
                'is_active' => true,
                'is_verified' => true,
                'phone_verified_at' => now(),
            ]
        );

        $riderUser->rider()->updateOrCreate(
            ['user_id' => $riderUser->id],
            [
                'vehicle_type' => 'motorcycle',
                'city' => 'Moshi',
                'is_online' => true,
                'is_verified' => true,
            ]
        );

        // 4. List some items for the Demo Store
        $masterItems = MasterProduct::limit(3)->get();
        foreach ($masterItems as $item) {
            Product::updateOrCreate(
                ['merchant_id' => $merchant->id, 'master_product_id' => $item->id],
                [
                    'price' => rand(1500, 5000),
                    'stock_count' => rand(10, 100),
                    'is_available' => true,
                ]
            );
        }
    }
}
