<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('delivery_pricing_rules', function (Blueprint $table) {
            $table->decimal('max_distance', 8, 2)->default(15.00)->after('per_km_fee');
        });
    }

    public function down(): void
    {
        Schema::table('delivery_pricing_rules', function (Blueprint $table) {
            $table->dropColumn('max_distance');
        });
    }
};
