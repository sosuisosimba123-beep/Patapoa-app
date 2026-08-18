<?php

namespace Database\Seeders;

use App\Models\User;
use App\Models\Merchant;
use App\Models\DeliveryPartner;
use App\Models\Wallet;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class TestUserSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $user = User::updateOrCreate(
            ['phone' => '0622606497'],
            [
                'name' => 'Eutychus Daudi Massambu',
                'email' => 'Sosuisosimba123@gmail.com',
                'password' => Hash::make('password'),
                'user_type' => 'customer', // Initial role, will morph on login
                'is_active' => true,
                'is_verified' => true,
            ]
        );

        // Create Merchant Profile
        Merchant::updateOrCreate(
            ['user_id' => $user->id],
            [
                'store_name' => 'Eutychus Testing Store',
                'description' => 'A store created for testing purposes.',
                'address' => 'Sample Street, Dar es Salaam',
                'city' => 'Dar es Salaam',
                'is_verified' => true,
                'is_online' => true,
            ]
        );

        // Create Rider Profile
        DeliveryPartner::updateOrCreate(
            ['user_id' => $user->id],
            [
                'vehicle_type' => 'motorcycle',
                'license_plate' => 'T 123 ABC',
                'city' => 'Dar es Salaam',
                'is_verified' => true,
                'is_online' => true,
            ]
        );

        // Create Wallet
        Wallet::updateOrCreate(
            ['user_id' => $user->id, 'wallet_type' => 'customer'],
            [
                'balance' => 1000000, // 1M TZS for testing
                'currency' => 'TZS',
            ]
        );
    }
}
