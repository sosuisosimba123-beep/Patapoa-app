<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\User;
use Illuminate\Support\Facades\Hash;

class AdminSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        User::create([
            'name' => 'Admin User',
            'email' => 'admin@patapoa.co.tz',
            'phone' => '+255700000000',
            'password' => Hash::make('admin123'),
            'user_type' => 'admin',
            'is_active' => true,
            'is_verified' => true,
        ]);
    }
}
