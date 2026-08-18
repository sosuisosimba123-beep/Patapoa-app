<?php

namespace App\Services;

use App\Models\Merchant;
use App\Models\Order;
use App\Models\Transaction;
use Illuminate\Support\Facades\DB;

class MerchantService
{
    /**
     * Get aggregated dashboard statistics for a merchant.
     */
    public function getDashboardStats(Merchant $merchant)
    {
        $totalOrders = Order::whereHas('orderItems', function ($query) use ($merchant) {
            $query->where('merchant_id', $merchant->id);
        })->count();

        $pendingOrders = Order::whereHas('orderItems', function ($query) use ($merchant) {
            $query->where('merchant_id', $merchant->id);
        })->whereIn('status', ['paid_securely', 'confirmed', 'preparing'])->count();

        $completedOrders = Order::whereHas('orderItems', function ($query) use ($merchant) {
            $query->where('merchant_id', $merchant->id);
        })->where('status', 'completed')->count();

        $productsCount = $merchant->products()->where('is_available', true)->count();
        $payoutSetup = !empty($merchant->payout_account);

        $lowStockCount = $merchant->products()
            ->where('stock_count', '<=', 5)
            ->where('is_available', true)
            ->count();

        $totalRevenue = Transaction::where('user_id', $merchant->user_id)
            ->where('type', 'earning')
            ->where('status', 'completed')
            ->sum('amount');

        $wallet = $merchant->user->wallet;

        $recentOrders = Order::whereHas('orderItems', function ($query) use ($merchant) {
                $query->where('merchant_id', $merchant->id);
            })
            ->whereIn('status', ['paid_securely', 'confirmed'])
            ->with(['customer', 'orderItems' => function($q) use ($merchant) {
                $q->where('merchant_id', $merchant->id);
            }])
            ->orderBy('created_at', 'desc')
            ->limit(5)
            ->get();

        return [
            'store_name' => $merchant->store_name,
            'city' => $merchant->city,
            'total_orders' => $totalOrders,
            'pending_orders' => $pendingOrders,
            'completed_orders' => $completedOrders,
            'products_count' => $productsCount,
            'low_stock_count' => $lowStockCount,
            'payout_setup' => $payoutSetup,
            'total_revenue' => $totalRevenue,
            'pending_balance' => $wallet ? $wallet->pending_balance : 0,
            'available_balance' => $wallet ? $wallet->balance : 0,
            'rating' => $merchant->rating,
            'is_online' => $merchant->is_online,
            'latitude' => $merchant->latitude,
            'longitude' => $merchant->longitude,
            'recent_orders' => $recentOrders,
        ];
    }
}
