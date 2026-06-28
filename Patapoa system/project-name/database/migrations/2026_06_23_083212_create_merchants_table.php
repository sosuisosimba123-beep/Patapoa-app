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
        Schema::create('merchants', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->string('store_name');
            $table->text('description')->nullable();
            $table->string('business_reg_no')->nullable();
            $table->text('address');
            $table->decimal('latitude', 10, 8)->nullable();
            $table->decimal('longitude', 11, 8)->nullable();
            $table->string('city');
            $table->string('region')->nullable();
            $table->decimal('commission_rate', 5, 2)->default(10.00);
            $table->enum('payout_method', ['mpesa', 'tigo_pesa', 'bank'])->default('mpesa');
            $table->string('payout_account')->nullable();
            $table->boolean('is_verified')->default(false);
            $table->boolean('is_online')->default(true);
            $table->decimal('rating', 3, 2)->default(0);
            $table->integer('total_orders')->default(0);
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('merchants');
    }
};
