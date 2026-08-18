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
        Schema::create('master_products', function (Blueprint $table) {
            $table->id();
            $table->foreignId('category_id')->constrained()->onDelete('cascade');
            $table->string('name');
            $table->string('brand')->nullable();
            $table->string('unit')->nullable(); // e.g., 1kg, 500ml
            $table->text('description')->nullable();
            $table->string('primary_image_url');
            $table->string('backup_image_url')->nullable();
            $table->string('slug')->unique();
            $table->json('search_tags')->nullable();
            $table->timestamps();

            $table->index('name');
            $table->index('brand');
        });

        // Modify products table to link to master_products
        Schema::table('products', function (Blueprint $table) {
            if (!Schema::hasColumn('products', 'master_product_id')) {
                $table->foreignId('master_product_id')->nullable()->after('category_id')->constrained('master_products')->onDelete('cascade');
            }

            // Use portable Schema builder instead of raw MySQL 'MODIFY'
            $table->string('name')->nullable()->change();
            $table->json('images')->nullable()->change();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('products', function (Blueprint $table) {
            $table->dropForeign(['master_product_id']);
            $table->dropColumn('master_product_id');
            $table->string('name')->nullable(false)->change();
            $table->string('images')->nullable(false)->change();
        });

        Schema::dropIfExists('master_products');
    }
};
