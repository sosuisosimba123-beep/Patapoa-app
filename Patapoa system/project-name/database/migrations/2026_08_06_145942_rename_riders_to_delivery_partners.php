<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // 1. Rename table only if 'riders' exists and 'delivery_partners' does not
        if (Schema::hasTable('riders') && !Schema::hasTable('delivery_partners')) {
            Schema::rename('riders', 'delivery_partners');
        }

        // 2. Rename column only if 'rider_id' still exists in orders
        if (Schema::hasColumn('orders', 'rider_id') && !Schema::hasColumn('orders', 'delivery_partner_id')) {
            Schema::table('orders', function (Blueprint $table) {
                $table->renameColumn('rider_id', 'delivery_partner_id');
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        if (Schema::hasTable('delivery_partners') && !Schema::hasTable('riders')) {
            Schema::rename('delivery_partners', 'riders');
        }

        if (Schema::hasColumn('orders', 'delivery_partner_id') && !Schema::hasColumn('orders', 'rider_id')) {
            Schema::table('orders', function (Blueprint $table) {
                $table->renameColumn('delivery_partner_id', 'rider_id');
            });
        }
    }
};
