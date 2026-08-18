<?php

namespace Database\Seeders;

use App\Models\User;
use App\Models\Merchant;
use App\Models\DeliveryPartner;
use App\Models\Wallet;
use App\Models\Product;
use App\Models\SecondaryCategory;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DummyTestingSeeder extends Seeder
{
    public function run(): void
    {
        // 1. Create Dummy Merchant
        $merchantUser = User::updateOrCreate(
            ['phone' => '0711000001'],
            [
                'name' => 'Testing Merchant',
                'email' => 'merchant@test.com',
                'password' => Hash::make('password123'),
                'user_type' => 'merchant',
                'is_active' => true,
                'is_verified' => true,
            ]
        );

        $merchant = Merchant::updateOrCreate(
            ['user_id' => $merchantUser->id],
            [
                'store_name' => 'Patapoa Test Store',
                'description' => 'A verified dummy store for system testing.',
                'address' => 'Victoria, Bagamoyo Road',
                'city' => 'Dar es Salaam',
                'latitude' => -6.7766,
                'longitude' => 39.2415,
                'is_verified' => true,
                'is_online' => true,
            ]
        );

        $merchantUser->wallet()->updateOrCreate(
            ['wallet_type' => 'merchant'],
            ['balance' => 0, 'currency' => 'TZS']
        );

        // Add some products to the Merchant
        $sec = SecondaryCategory::where('name', 'flour & grains')->first();

        Product::updateOrCreate(
            ['merchant_id' => $merchant->id, 'name' => 'Test Item 1'],
            [
                'secondary_category_id' => $sec?->id,
                'description' => 'Testing product for order flow',
                'price' => 15000,
                'stock_count' => 100,
                'is_available' => true,
            ]
        );

        Product::updateOrCreate(
            ['merchant_id' => $merchant->id, 'name' => 'Test Item 2'],
            [
                'secondary_category_id' => $sec?->id,
                'description' => 'Another testing product',
                'price' => 25000,
                'stock_count' => 50,
                'is_available' => true,
            ]
        );

        // 2. Create Dummy Rider
        $riderUser = User::updateOrCreate(
            ['phone' => '0711000002'],
            [
                'name' => 'Testing Rider',
                'email' => 'rider@test.com',
                'password' => Hash::make('password123'),
                'user_type' => 'rider',
                'is_active' => true,
                'is_verified' => true,
            ]
        );

        DeliveryPartner::updateOrCreate(
            ['user_id' => $riderUser->id],
            [
                'vehicle_type' => 'motorcycle',
                'license_plate' => 'T 999 TEST',
                'city' => 'Dar es Salaam',
                'current_latitude' => -6.7760,
                'current_longitude' => 39.2420,
                'is_verified' => true,
                'is_online' => true,
                'is_on_delivery' => false,
            ]
        );

        $riderUser->wallet()->updateOrCreate(
            ['wallet_type' => 'rider'],
            ['balance' => 0, 'currency' => 'TZS']
        );

        // 3. Create Dummy Customer (You)
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
            ['balance' => 100000, 'currency' => 'TZS'] // 100k TZS for testing
        );

        // Add a default address for the customer
        $customerUser->addresses()->updateOrCreate(
            ['label' => 'Home'],
            [
                'recipient_name' => 'Test Customer',
                'phone' => '0711000003',
                'address_line_1' => 'Mikocheni B, Dar es Salaam',
                'city' => 'Dar es Salaam',
                'latitude' => -6.7915,
                'longitude' => 39.2324,
                'is_default' => true,
            ]
        );
    }
}
