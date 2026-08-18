<?php

namespace Database\Seeders;

use App\Models\User;
use App\Models\Merchant;
use App\Models\Product;
use App\Models\SecondaryCategory;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class ManualOrderSimulationSeeder extends Seeder
{
    public function run(): void
    {
        // 1. Create the specific testing customer (You)
        $customerUser = User::updateOrCreate(
            ['phone' => '0711000003'],
            [
                'name' => 'Test Customer',
                'email' => 'customer@test.com',
                'password' => Hash::make('password123'),
                'user_type' => 'customer',
                'is_active' => true,
                'is_verified' => true,
            ]
        );

        $customerUser->wallet()->updateOrCreate(
            ['wallet_type' => 'customer'],
            ['balance' => 100000, 'currency' => 'TZS']
        );

        // Add a default address for the customer (Dar es Salaam center)
        $customerUser->addresses()->updateOrCreate(
            ['label' => 'Home'],
            [
                'recipient_name' => 'Test Customer',
                'phone' => '0711000003',
                'address_line_1' => 'Posta Mpya, Dar es Salaam',
                'city' => 'Dar es Salaam',
                'latitude' => -6.8163,
                'longitude' => 39.2803,
                'is_default' => true,
            ]
        );

        // 2. Create a Simulation Merchant
        $merchantUser = User::updateOrCreate(
            ['phone' => '0000000000'],
            [
                'name' => 'Global Simulation Merchant',
                'email' => 'simulation@patapoa.com',
                'password' => Hash::make('password123'),
                'user_type' => 'merchant',
                'is_active' => true,
                'is_verified' => true,
            ]
        );

        $merchant = Merchant::updateOrCreate(
            ['user_id' => $merchantUser->id],
            [
                'store_name' => 'Global Simulation Store',
                'description' => 'A special store for manual order simulation, visible everywhere.',
                'address' => 'Anywhere, Tanzania',
                'city' => 'Simulation City',
                'latitude' => -6.7766,
                'longitude' => 39.2415,
                'is_verified' => true,
                'is_online' => true,
                'rating' => 5.0,
            ]
        );

        $merchantUser->wallet()->updateOrCreate(
            ['wallet_type' => 'merchant'],
            ['balance' => 0, 'currency' => 'TZS']
        );

        // 3. Ensure a category exists
        $sec = SecondaryCategory::where('slug', 'flour-grains')->first();

        // 4. Create a Dummy Product with the new fields (brand, unit)
        Product::updateOrCreate(
            ['merchant_id' => $merchant->id, 'name' => 'Simulation Dummy Product'],
            [
                'secondary_category_id' => $sec?->id,
                'brand' => 'Patapoa',
                'unit' => '1 unit',
                'description' => 'A dummy product for manual testing. Can be ordered from any location.',
                'price' => 1000,
                'stock_count' => 9999,
                'is_available' => true,
                'is_featured' => true,
                'images' => ['https://via.placeholder.com/500?text=Simulation+Product'],
            ]
        );
    }
}
