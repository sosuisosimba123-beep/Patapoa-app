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
        // 1. Primary Categories Table
        Schema::create('primary_categories', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('slug')->unique();
            $table->string('image_url')->nullable();
            $table->boolean('is_active')->default(true);
            $table->integer('sort_order')->default(0);
            $table->timestamps();
        });

        // 2. Secondary Categories Table
        Schema::create('secondary_categories', function (Blueprint $table) {
            $table->id();
            $table->foreignId('primary_category_id')->constrained('primary_categories')->onDelete('cascade');
            $table->string('name');
            $table->string('slug')->unique();
            $table->string('image_url')->nullable(); // For the specific .png assets
            $table->boolean('is_active')->default(true);
            $table->integer('sort_order')->default(0);
            $table->timestamps();
        });

        // 3. Link Products and MasterProducts to Secondary Categories
        Schema::table('products', function (Blueprint $table) {
            $table->foreignId('secondary_category_id')->nullable()->after('merchant_id')->constrained('secondary_categories')->onDelete('set null');
        });

        Schema::table('master_products', function (Blueprint $table) {
            $table->foreignId('secondary_category_id')->nullable()->after('id')->constrained('secondary_categories')->onDelete('set null');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('master_products', function (Blueprint $table) {
            $table->dropForeign(['secondary_category_id']);
            $table->dropColumn('secondary_category_id');
        });

        Schema::table('products', function (Blueprint $table) {
            $table->dropForeign(['secondary_category_id']);
            $table->dropColumn('secondary_category_id');
        });

        Schema::dropIfExists('secondary_categories');
        Schema::dropIfExists('primary_categories');
    }
};
