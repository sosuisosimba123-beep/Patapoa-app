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
        // Products table indexes
        Schema::table('products', function (Blueprint $table) {
            $table->index('merchant_id');
            $table->index('category_id');
            $table->index(['is_available', 'is_featured']);
            $table->index('price');
            $table->index('created_at');
            $table->index('name');
            $table->index('stock_count');
        });

        // Orders table indexes
        Schema::table('orders', function (Blueprint $table) {
            $table->index('customer_id');
            $table->index('rider_id');
            $table->index('address_id');
            $table->index('status');
            $table->index('payment_status');
            $table->index('created_at');
            $table->index(['status', 'rider_id']); // For available orders query
            $table->index(['customer_id', 'created_at']); // For customer orders
        });

        // Order items table indexes
        Schema::table('order_items', function (Blueprint $table) {
            $table->index('order_id');
            $table->index('merchant_id');
            $table->index('product_id');
        });

        // Riders table indexes
        Schema::table('riders', function (Blueprint $table) {
            $table->index('is_online');
            $table->index('is_on_delivery');
            $table->index('is_verified');
            $table->index('user_id');
            $table->index('last_location_update');
            $table->index('city');
        });

        // Merchants table indexes
        Schema::table('merchants', function (Blueprint $table) {
            $table->index('is_verified');
            $table->index('is_online');
            $table->index('user_id');
            $table->index('city');
        });

        // Addresses table indexes
        Schema::table('addresses', function (Blueprint $table) {
            $table->index('user_id');
            $table->index('is_default');
        });

        // Transactions table indexes
        Schema::table('transactions', function (Blueprint $table) {
            $table->index('user_id');
            $table->index('order_id');
            $table->index('type');
            $table->index('status');
            $table->index('created_at');
            $table->index(['user_id', 'type', 'status']);
        });

        // Notifications table indexes
        Schema::table('notifications', function (Blueprint $table) {
            $table->index('user_id');
            $table->index('is_read');
            $table->index('created_at');
        });

        // Users table indexes
        Schema::table('users', function (Blueprint $table) {
            $table->index('phone');
            $table->index('user_type');
            $table->index('is_active');
        });

        // Categories table indexes
        Schema::table('categories', function (Blueprint $table) {
            $table->index('is_active');
            $table->index('sort_order');
        });

        // Wallets table indexes
        Schema::table('wallets', function (Blueprint $table) {
            $table->index('user_id');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('products', function (Blueprint $table) {
            $table->dropIndex(['merchant_id']);
            $table->dropIndex(['category_id']);
            $table->dropIndex(['is_available', 'is_featured']);
            $table->dropIndex(['price']);
            $table->dropIndex(['created_at']);
            $table->dropIndex(['name']);
            $table->dropIndex(['stock_count']);
        });

        Schema::table('orders', function (Blueprint $table) {
            $table->dropIndex(['customer_id']);
            $table->dropIndex(['rider_id']);
            $table->dropIndex(['address_id']);
            $table->dropIndex(['status']);
            $table->dropIndex(['payment_status']);
            $table->dropIndex(['created_at']);
            $table->dropIndex(['status', 'rider_id']);
            $table->dropIndex(['customer_id', 'created_at']);
        });

        Schema::table('order_items', function (Blueprint $table) {
            $table->dropIndex(['order_id']);
            $table->dropIndex(['merchant_id']);
            $table->dropIndex(['product_id']);
        });

        Schema::table('riders', function (Blueprint $table) {
            $table->dropIndex(['is_online']);
            $table->dropIndex(['is_on_delivery']);
            $table->dropIndex(['is_verified']);
            $table->dropIndex(['user_id']);
            $table->dropIndex(['last_location_update']);
            $table->dropIndex(['city']);
        });

        Schema::table('merchants', function (Blueprint $table) {
            $table->dropIndex(['is_verified']);
            $table->dropIndex(['is_online']);
            $table->dropIndex(['user_id']);
            $table->dropIndex(['city']);
        });

        Schema::table('addresses', function (Blueprint $table) {
            $table->dropIndex(['user_id']);
            $table->dropIndex(['is_default']);
        });

        Schema::table('transactions', function (Blueprint $table) {
            $table->dropIndex(['user_id']);
            $table->dropIndex(['order_id']);
            $table->dropIndex(['type']);
            $table->dropIndex(['status']);
            $table->dropIndex(['created_at']);
            $table->dropIndex(['user_id', 'type', 'status']);
        });

        Schema::table('notifications', function (Blueprint $table) {
            $table->dropIndex(['user_id']);
            $table->dropIndex(['is_read']);
            $table->dropIndex(['created_at']);
        });

        Schema::table('users', function (Blueprint $table) {
            $table->dropIndex(['phone']);
            $table->dropIndex(['user_type']);
            $table->dropIndex(['is_active']);
        });

        Schema::table('categories', function (Blueprint $table) {
            $table->dropIndex(['is_active']);
            $table->dropIndex(['sort_order']);
        });

        Schema::table('wallets', function (Blueprint $table) {
            $table->dropIndex(['user_id']);
        });
    }
};
