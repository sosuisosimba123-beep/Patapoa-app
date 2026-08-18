<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('clickpesa_payments', function (Blueprint $table) {
            $id = $table->id();
            $table->string('reference_id')->unique();
            $table->string('external_id')->nullable();
            $table->enum('payment_method', ['ussd', 'card', 'payout']);
            $table->string('phone_number')->nullable();
            $table->string('card_number_masked')->nullable();
            $table->decimal('amount', 15, 2);
            $table->string('currency')->default('TZS');
            $table->string('status')->default('pending'); // pending, processing, successful, failed, cancelled
            $table->text('status_detail')->nullable();
            $table->json('request_payload')->nullable();
            $table->json('response_payload')->nullable();
            $table->timestamp('paid_at')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('clickpesa_payments');
    }
};
