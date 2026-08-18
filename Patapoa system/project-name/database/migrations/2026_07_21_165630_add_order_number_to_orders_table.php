<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->string('order_number')->unique()->nullable()->after('id');
        });

        // Populate existing orders if any
        $orders = \App\Models\Order::all();
        foreach ($orders as $order) {
            $order->update([
                'order_number' => 'PAT-' . str_pad($order->id, 6, '0', STR_PAD_LEFT)
            ]);
        }
    }

    public function down(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->dropColumn('order_number');
        });
    }
};
