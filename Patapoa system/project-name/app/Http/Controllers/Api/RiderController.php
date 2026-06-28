<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\Rider;
use App\Models\Transaction;
use App\Models\Wallet;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;

class RiderController extends Controller
{
    public function updateLocation(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'latitude' => 'required|numeric|between:-90,90',
            'longitude' => 'required|numeric|between:-180,180',
        ]);

        if ($validator->fails()) {
            return $this->errorResponse('Validation failed', 422, $validator->errors()->toArray());
        }

        $rider = $request->user()->rider;
        $riderId = $rider->id;
        $throttleKey = "rider_location_throttle:{$riderId}";

        // Rate limit: max 1 location update per rider per 15 seconds
        if (Cache::has($throttleKey)) {
            $lastUpdate = Cache::get($throttleKey);
            $secondsSince = now()->diffInSeconds($lastUpdate);
            
            return $this->successResponse([
                'throttled' => true,
                'last_update' => $lastUpdate,
                'seconds_since' => $secondsSince,
                'cooldown_remaining' => max(0, 15 - $secondsSince),
            ], 'Location update throttled — too frequent');
        }

        // Cache the update timestamp before writing to DB
        Cache::put($throttleKey, now(), 15);

        $rider->update([
            'current_latitude' => $request->latitude,
            'current_longitude' => $request->longitude,
            'last_location_update' => now(),
        ]);

        // Also cache rider location for fast reads (used by customer tracking)
        Cache::put("rider_location:{$riderId}", [
            'latitude' => $request->latitude,
            'longitude' => $request->longitude,
            'updated_at' => now()->toDateTimeString(),
        ], 60);

        return $this->successResponse(null, 'Location updated');
    }

    public function goOnline(Request $request)
    {
        $rider = $request->user()->rider;
        $rider->update(['is_online' => true]);

        return $this->successResponse(null, 'You are now online');
    }

    public function goOffline(Request $request)
    {
        $rider = $request->user()->rider;
        
        if ($rider->is_on_delivery) {
            return $this->errorResponse('Cannot go offline while on delivery', 422);
        }

        $rider->update(['is_online' => false]);

        return $this->successResponse(null, 'You are now offline');
    }

    public function availableOrders(Request $request)
    {
        $rider = $request->user()->rider;

        if (!$rider->is_online || $rider->is_on_delivery) {
            return $this->successResponse([], 'No available orders');
        }

        // Get orders ready for pickup without assigned riders
        $query = Order::where('status', 'ready_for_pickup')
            ->whereNull('rider_id')
            ->with(['address', 'orderItems'])
            ->orderBy('created_at', 'desc');

        $orders = $this->paginateQuery($query, $request, 10, 50);

        return $this->paginatedResponse($orders, 'Available orders retrieved successfully');
    }

    public function acceptOrder(Request $request, $id)
    {
        $rider = $request->user()->rider;

        if (!$rider->is_online) {
            return $this->errorResponse('You must be online to accept orders', 422);
        }

        if ($rider->is_on_delivery) {
            return $this->errorResponse('You already have an active delivery', 422);
        }

        $order = Order::findOrFail($id);

        if ($order->status !== 'ready_for_pickup' || $order->rider_id) {
            return $this->errorResponse('Order is not available', 422);
        }

        try {
            DB::beginTransaction();

            $order->update([
                'rider_id' => $rider->id,
                'status' => 'rider_assigned',
                'assigned_at' => now(),
            ]);

            $rider->update(['is_on_delivery' => true]);

            DB::commit();

            // TODO: Send push notification to merchant and customer

            return $this->successResponse($order->fresh(), 'Order accepted successfully');

        } catch (\Exception $e) {
            DB::rollBack();
            return $this->errorResponse('Failed to accept order', 500);
        }
    }

    public function updateOrderStatus(Request $request, $id)
    {
        $order = Order::findOrFail($id);
        $rider = $request->user()->rider;

        if ($order->rider_id !== $rider->id) {
            return $this->errorResponse('Unauthorized', 403);
        }

        $validator = Validator::make($request->all(), [
            'status' => 'required|in:rider_heading_to_pickup,at_pickup,picked_up,heading_to_customer,at_dropoff,delivered',
            'latitude' => 'nullable|numeric|between:-90,90',
            'longitude' => 'nullable|numeric|between:-180,180',
        ]);

        if ($validator->fails()) {
            return $this->errorResponse('Validation failed', 422, $validator->errors()->toArray());
        }

        $validTransitions = [
            'rider_assigned' => ['rider_heading_to_pickup'],
            'rider_heading_to_pickup' => ['at_pickup'],
            'at_pickup' => ['picked_up'],
            'picked_up' => ['heading_to_customer'],
            'heading_to_customer' => ['at_dropoff'],
            'at_dropoff' => ['delivered'],
        ];

        if (!isset($validTransitions[$order->status]) || 
            !in_array($request->status, $validTransitions[$order->status])) {
            return $this->errorResponse('Invalid status transition', 422);
        }

        $order->update(['status' => $request->status]);

        // Update timestamps
        if ($request->status === 'picked_up') {
            $order->update(['picked_up_at' => now()]);
        }

        if ($request->status === 'delivered') {
            $order->update([
                'delivered_at' => now(),
                'status' => 'completed',
            ]);

            // Mark rider as available
            $rider->update(['is_on_delivery' => false]);
            $rider->increment('total_deliveries');

            // Calculate and credit rider earnings
            $this->creditRiderEarnings($rider, $order);
        }

        // TODO: Send push notification to customer

        return $this->successResponse($order->fresh(), 'Order status updated successfully');
    }

    public function earnings(Request $request)
    {
        $rider = $request->user()->rider;
        $wallet = $request->user()->wallet;

        $totalEarnings = $request->user()->transactions()
            ->where('type', 'earning')
            ->where('status', 'completed')
            ->sum('amount');

        $pendingEarnings = $request->user()->transactions()
            ->where('type', 'earning')
            ->where('status', 'pending')
            ->sum('amount');

        // Get paginated earnings history
        $query = $request->user()->transactions()
            ->where('type', 'earning')
            ->orderBy('created_at', 'desc');

        $transactions = $this->paginateQuery($query, $request, 20, 100);

        return $this->successResponse([
            'total_earnings' => $totalEarnings,
            'pending_earnings' => $pendingEarnings,
            'available_balance' => $wallet ? $wallet->balance : 0,
            'total_deliveries' => $rider->total_deliveries,
            'rating' => $rider->rating,
            'transactions' => $transactions->items(),
            'meta' => [
                'current_page' => $transactions->currentPage(),
                'last_page' => $transactions->lastPage(),
                'per_page' => $transactions->perPage(),
                'total' => $transactions->total(),
            ],
        ], 'Earnings retrieved successfully');
    }

    public function requestPayout(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'amount' => 'required|numeric|min:1000',
            'payout_method' => 'required|in:mpesa,tigo_pesa',
        ]);

        if ($validator->fails()) {
            return $this->errorResponse('Validation failed', 422, $validator->errors()->toArray());
        }

        $wallet = $request->user()->wallet;

        if (!$wallet || $wallet->balance < $request->amount) {
            return $this->errorResponse('Insufficient balance', 422);
        }

        try {
            DB::beginTransaction();

            $wallet->decrement('balance', $request->amount);

            Transaction::create([
                'user_id' => $request->user()->id,
                'type' => 'payout',
                'status' => 'pending',
                'amount' => $request->amount,
                'currency' => 'TZS',
                'payment_method' => $request->payout_method,
                'description' => 'Payout request',
                'metadata' => [
                    'payout_method' => $request->payout_method,
                ],
            ]);

            DB::commit();

            return $this->successResponse(null, 'Payout request submitted');

        } catch (\Exception $e) {
            DB::rollBack();
            return $this->errorResponse('Payout request failed', 500);
        }
    }

    public function riderOrders(Request $request)
    {
        $rider = $request->user()->rider;
        
        $query = Order::where('rider_id', $rider->id)
            ->with(['orderItems', 'customer', 'address'])
            ->orderBy('created_at', 'desc');
        
        $orders = $this->paginateQuery($query, $request, 20, 100);
        
        return $this->paginatedResponse($orders, 'Rider orders retrieved successfully');
    }
    
    public function profile(Request $request)
    {
        $riderId = $request->user()->id;
        $cacheKey = "rider_profile:{$riderId}";

        $data = $this->remember($cacheKey, function () use ($request) {
            $user = $request->user()->load(['rider', 'wallet']);
            $rider = $user->rider;
            
            return [
                'id' => $user->id,
                'name' => $user->name,
                'phone' => $user->phone,
                'email' => $user->email,
                'city' => $rider->city ?? 'Dar es Salaam',
                'rating' => $rider->rating,
                'total_deliveries' => $rider->total_deliveries,
                'vehicle_type' => $rider->vehicle_type,
                'license_plate' => $rider->license_plate,
                'driver_license' => $rider->driver_license,
                'is_online' => $rider->is_online,
                'balance' => $user->wallet ? $user->wallet->balance : 0,
                'tier' => $rider->tier ?? 'Bronze',
            ];
        }, 60);
        
        return $this->successResponse($data, 'Profile retrieved successfully');
    }

    private function creditRiderEarnings($rider, $order)
    {
        // Calculate rider earnings (e.g., 70% of delivery fee)
        $riderEarning = $order->delivery_fee * 0.7;

        Transaction::create([
            'user_id' => $rider->user_id,
            'order_id' => $order->id,
            'type' => 'earning',
            'status' => 'completed',
            'amount' => $riderEarning,
            'currency' => 'TZS',
            'payment_method' => 'wallet',
            'description' => 'Delivery earning for order #' . $order->id,
            'processed_at' => now(),
        ]);

        // Update wallet
        $wallet = $rider->user()->wallet;
        if ($wallet) {
            $wallet->increment('balance', $riderEarning);
        }
    }
}
