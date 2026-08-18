<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('platform_settings', function (Blueprint $table) {
            $table->id();
            $table->string('key')->unique();
            $table->text('value')->nullable();
            $table->string('type')->default('string'); // string, int, float, boolean
            $table->string('description')->nullable();
            $table->timestamps();
        });

        // Seed default values
        DB::table('platform_settings')->insert([
            [
                'key' => 'merchant_commission_rate',
                'value' => '0.05',
                'type' => 'float',
                'description' => 'Default commission percentage charged to merchants (0.05 = 5%)',
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'key' => 'rider_commission_rate',
                'value' => '0.05',
                'type' => 'float',
                'description' => 'Default commission percentage charged on delivery fees (0.05 = 5%)',
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'key' => 'convenience_fee',
                'value' => '0',
                'type' => 'float',
                'description' => 'Flat platform fee charged to customers per order',
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ]);
    }

    public function down(): void
    {
        Schema::dropIfExists('platform_settings');
    }
};
