<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        if (Schema::hasTable('products') && !Schema::hasColumn('products', 'master_product_id')) {
            Schema::table('products', function (Blueprint $table) {
                $table->foreignId('master_product_id')->nullable()->after('category_id')->constrained('master_products')->onDelete('cascade');
                $table->string('name')->nullable()->change();
                $table->string('images')->nullable()->change();
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        if (Schema::hasColumn('products', 'master_product_id')) {
            Schema::table('products', function (Blueprint $table) {
                $table->dropForeign(['master_product_id']);
                $table->dropColumn('master_product_id');
            });
        }
    }
};
