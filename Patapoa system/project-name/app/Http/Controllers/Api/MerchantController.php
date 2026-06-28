<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use Illuminate\Http\Request;

class MerchantController extends Controller
{
    public function dashboard(Request $request)
    {
        $merchant = $request->user()->merchant;

        $totalOrders = Order::whereHas('orderItems', function ($query) use ($merchant) {
            $query->where('merchant_id', $merchant->id);
        })->count();

        $pendingOrders = Order::whereHas('orderItems', function ($query) use ($merchant) {
            $query->where('merchant_id', $merchant->id);
        })->whereIn('status', ['placed', 'confirmed', 'preparing'])->count();

        $completedOrders = Order::whereHas('orderItems', function ($query) use ($merchant) {
            $query->where('merchant_id', $merchant->id);
        })->where('status', 'completed')->count();

        $totalRevenue = $request->user()->transactions()
            ->where('type', 'earning')
            ->where('status', 'completed')
            ->sum('amount');

        return $this->successResponse([
            'total_orders' => $totalOrders,
            'pending_orders' => $pendingOrders,
            'completed_orders' => $completedOrders,
            'total_revenue' => $totalRevenue,
            'rating' => $merchant->rating,
            'is_online' => $merchant->is_online,
        ], 'Dashboard data retrieved successfully');
    }

    public function orders(Request $request)
    {
        $merchant = $request->user()->merchant;

        $query = Order::whereHas('orderItems', function ($query) use ($merchant) {
            $query->where('merchant_id', $merchant->id);
        })
        ->with(['orderItems', 'customer', 'address'])
        ->orderBy('created_at', 'desc');

        $orders = $this->paginateQuery($query, $request, 20, 100);

        return $this->paginatedResponse($orders, 'Merchant orders retrieved successfully');
    }

    public function updateOrderStatus(Request $request, $id)
    {
        $order = Order::findOrFail($id);
        $merchant = $request->user()->merchant;

        // Verify this order belongs to this merchant
        $hasOrderItem = $order->orderItems()->where('merchant_id', $merchant->id)->exists();
        if (!$hasOrderItem) {
            return $this->errorResponse('Unauthorized', 403);
        }

        $validator = Validator::make($request->all(), [
            'status' => 'required|in:confirmed,preparing,ready_for_pickup',
        ]);

        if ($validator->fails()) {
            return $this->errorResponse('Validation failed', 422, $validator->errors()->toArray());
        }

        $validTransitions = [
            'placed' => ['confirmed'],
            'confirmed' => ['preparing'],
            'preparing' => ['ready_for_pickup'],
        ];

        if (!isset($validTransitions[$order->status]) || 
            !in_array($request->status, $validTransitions[$order->status])) {
            return $this->errorResponse('Invalid status transition', 422);
        }

        $order->update(['status' => $request->status]);

        // Update timestamp based on status
        if ($request->status === 'confirmed') {
            $order->update(['confirmed_at' => now()]);
        }

        // TODO: Send push notification to customer

        return $this->successResponse($order->fresh(), 'Order status updated successfully');
    }
}
