<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('delivery_pricing_rules', function (Blueprint $table) {
            $table->id();
            $table->string('zone_name');
            $table->decimal('base_fee', 10, 2)->default(2000);
            $table->decimal('per_km_fee', 10, 2)->default(500);
            $table->decimal('min_basket_value_for_free_delivery', 10, 2)->nullable();
            $table->decimal('surge_multiplier', 3, 2)->default(1.0);
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        // Add surge pricing log to track history
        Schema::create('surge_pricing_logs', function (Blueprint $table) {
            $table->id();
            $table->string('reason'); // e.g., "Heavy Rain", "Peak Hour"
            $table->decimal('multiplier', 3, 2);
            $table->timestamp('starts_at');
            $table->timestamp('ends_at')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('delivery_pricing_rules');
        Schema::dropIfExists('surge_pricing_logs');
    }
};
