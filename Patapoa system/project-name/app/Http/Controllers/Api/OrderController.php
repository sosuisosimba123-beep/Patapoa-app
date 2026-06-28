<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Product;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;

class OrderController extends Controller
{
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'address_id' => 'required|exists:addresses,id',
            'items' => 'required|array|min:1',
            'items.*.product_id' => 'required|exists:products,id',
            'items.*.quantity' => 'required|integer|min:1',
            'customer_notes' => 'nullable|string',
            'payment_method' => 'required|in:mpesa,tigo_pesa,cash,wallet',
        ]);

        if ($validator->fails()) {
            return $this->errorResponse('Validation failed', 422, $validator->errors()->toArray());
        }

        try {
            DB::beginTransaction();

            $address = $request->user()->addresses()->findOrFail($request->address_id);
            
            $subtotal = 0;
            $orderItems = [];

            foreach ($request->items as $item) {
                $product = Product::findOrFail($item['product_id']);
                
                if (!$product->is_available || $product->stock_count < $item['quantity']) {
                    DB::rollBack();
                    return $this->errorResponse(
                        "Product '{$product->name}' is not available or insufficient stock", 
                        422
                    );
                }

                $itemSubtotal = $product->price * $item['quantity'];
                $subtotal += $itemSubtotal;

                $orderItems[] = [
                    'product_id' => $product->id,
                    'merchant_id' => $product->merchant_id,
                    'product_name' => $product->name,
                    'product_description' => $product->description,
                    'product_image' => $product->images[0] ?? null,
                    'quantity' => $item['quantity'],
                    'unit_price' => $product->price,
                    'subtotal' => $itemSubtotal,
                ];

                // Update stock
                $product->decrement('stock_count', $item['quantity']);
            }

            // Get merchant details for pickup location
            $firstProduct = Product::with('merchant')->findOrFail($request->items[0]['product_id']);
            $merchant = $firstProduct->merchant;
            $pickupLat = $merchant ? $merchant->latitude : null;
            $pickupLng = $merchant ? $merchant->longitude : null;

            $distance = 0;
            if ($pickupLat && $pickupLng && $address->latitude && $address->longitude) {
                $distance = $this->calculateDistance($pickupLat, $pickupLng, $address->latitude, $address->longitude);
            }
            $estimatedDuration = ceil($distance * 3) + 15; // 3 mins per km + 15 mins base

            $deliveryFee = $this->calculateDeliveryFee($distance);
            $platformFee = $subtotal * 0.05; // 5% platform fee
            $total = $subtotal + $deliveryFee + $platformFee;

            $order = Order::create([
                'customer_id' => $request->user()->id,
                'address_id' => $request->address_id,
                'status' => 'placed',
                'subtotal' => $subtotal,
                'delivery_fee' => $deliveryFee,
                'platform_fee' => $platformFee,
                'total' => $total,
                'payment_method' => $request->payment_method,
                'payment_status' => 'pending',
                'customer_notes' => $request->customer_notes,
                'placed_at' => now(),
                'pickup_latitude' => $pickupLat,
                'pickup_longitude' => $pickupLng,
                'dropoff_latitude' => $address->latitude,
                'dropoff_longitude' => $address->longitude,
                'estimated_distance_km' => $distance,
                'estimated_duration_minutes' => $estimatedDuration,
            ]);

            foreach ($orderItems as $item) {
                $order->orderItems()->create($item);
            }

            DB::commit();

            return $this->successResponse($order->load('orderItems.address'), 'Order created successfully', 201);

        } catch (\Exception $e) {
            DB::rollBack();
            return $this->errorResponse('Failed to create order', 500);
        }
    }

    public function customerOrders(Request $request)
    {
        $query = $request->user()->orders()
            ->with(['orderItems.product', 'address', 'rider.user'])
            ->orderBy('created_at', 'desc');

        $orders = $this->paginateQuery($query, $request, 20, 100);

        return $this->paginatedResponse($orders, 'Orders retrieved successfully');
    }

    public function show(Request $request, $id)
    {
        $order = Order::with(['orderItems.product', 'address', 'rider.user'])
            ->findOrFail($id);

        if ($order->customer_id !== $request->user()->id) {
            return $this->errorResponse('Unauthorized', 403);
        }

        return $this->successResponse($order, 'Order retrieved successfully');
    }

    public function tracking(Request $request, $id)
    {
        $order = Order::with(['address'])->findOrFail($id);

        if ($order->customer_id !== $request->user()->id) {
            return $this->errorResponse('Unauthorized', 403);
        }

        $distance = $order->estimated_distance_km;
        $eta = $order->estimated_duration_minutes;

        // Use cached rider location for fast reads, fallback to DB
        $riderData = null;
        if ($order->rider_id) {
            $cachedLocation = \Illuminate\Support\Facades\Cache::get("rider_location:{$order->rider_id}");
            
            if ($cachedLocation) {
                $riderData = [
                    'id' => $order->rider_id,
                    'current_latitude' => $cachedLocation['latitude'],
                    'current_longitude' => $cachedLocation['longitude'],
                    'last_location_update' => $cachedLocation['updated_at'],
                ];
            } else {
                // Fallback to DB query with selective fields
                $rider = $order->rider()->select('id', 'current_latitude', 'current_longitude', 'last_location_update', 'user_id')->first();
                if ($rider) {
                    $riderData = [
                        'id' => $rider->id,
                        'current_latitude' => $rider->current_latitude,
                        'current_longitude' => $rider->current_longitude,
                        'last_location_update' => $rider->last_location_update,
                    ];
                }
            }
        }

        if ($riderData && $riderData['current_latitude'] && $riderData['current_longitude']) {
            // Live distance between rider and dropoff
            $liveDistance = $this->calculateDistance(
                $riderData['current_latitude'],
                $riderData['current_longitude'],
                $order->dropoff_latitude,
                $order->dropoff_longitude
            );
            $distance = $liveDistance;
            $eta = ceil($liveDistance * 3); // 3 mins per km
        }

        return $this->successResponse([
            'order_id' => $order->id,
            'status' => $order->status,
            'rider' => $riderData,
            'dropoff_location' => [
                'latitude' => $order->dropoff_latitude,
                'longitude' => $order->dropoff_longitude,
                'address' => $order->address->address_line_1,
            ],
            'estimated_duration' => $eta,
            'distance_km' => round($distance, 2),
        ], 'Tracking data retrieved successfully');
    }

    public function cancel(Request $request, $id)
    {
        $order = Order::findOrFail($id);

        if ($order->customer_id !== $request->user()->id) {
            return $this->errorResponse('Unauthorized', 403);
        }

        if (!in_array($order->status, ['placed', 'confirmed'])) {
            return $this->errorResponse('Order cannot be cancelled at this stage', 422);
        }

        $order->update(['status' => 'cancelled']);

        // Restore stock
        foreach ($order->orderItems as $item) {
            Product::where('id', $item->product_id)->increment('stock_count', $item->quantity);
        }

        return $this->successResponse(null, 'Order cancelled successfully');
    }

    private function calculateDeliveryFee($distance)
    {
        $baseFee = 2000;
        $perKmFee = 500;
        return $baseFee + ($distance * $perKmFee);
    }

    private function calculateDistance($lat1, $lon1, $lat2, $lon2)
    {
        if (!$lat1 || !$lon1 || !$lat2 || !$lon2) {
            return 0;
        }
        $earthRadius = 6371; // km
        $dLat = deg2rad($lat2 - $lat1);
        $dLon = deg2rad($lon2 - $lon1);
        $a = sin($dLat/2) * sin($dLat/2) + cos(deg2rad($lat1)) * cos(deg2rad($lat2)) * sin($dLon/2) * sin($dLon/2);
        $c = 2 * atan2(sqrt($a), sqrt(1-$a));
        return $earthRadius * $c;
    }
}
