<?php

namespace App\Services;

use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Product;
use App\Models\Merchant;
use App\Models\DeliveryPricingRule;
use App\Models\PlatformSetting;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use App\Services\PushNotificationService;
use App\Services\OsmService;

class OrderService
{
    protected $notifications;
    protected $osm;

    public function __construct(PushNotificationService $notifications, OsmService $osm)
    {
        $this->notifications = $notifications;
        $this->osm = $osm;
    }

    /**
     * Create a new order with business logic validation.
     */
    public function createOrder(array $data, $user)
    {
        return DB::transaction(function () use ($data, $user) {
            $address = $user->addresses()->findOrFail($data['address_id']);

            $subtotal = 0;
            $orderItemsData = [];
            $merchantId = null;

            foreach ($data['items'] as $item) {
                $product = Product::with('masterProduct')->findOrFail($item['product_id']);

                if ($merchantId === null) {
                    $merchantId = $product->merchant_id;
                } elseif ($merchantId !== $product->merchant_id) {
                    throw new \Exception("All items in an order must be from the same merchant.");
                }

                if (!$product->is_available || $product->stock_count < $item['quantity']) {
                    throw new \Exception("Product '{$product->displayName}' is not available or insufficient stock");
                }

                $itemSubtotal = $product->price * $item['quantity'];
                $subtotal += $itemSubtotal;

                $orderItemsData[] = [
                    'product_id' => $product->id,
                    'merchant_id' => $product->merchant_id,
                    'product_name' => $product->display_name,
                    'brand' => $product->brand,
                    'unit' => $product->unit,
                    'product_description' => $product->description ?? $product->masterProduct?->description,
                    'product_image' => $product->display_image,
                    'quantity' => $item['quantity'],
                    'unit_price' => $product->price,
                    'subtotal' => $itemSubtotal,
                ];

                $product->decrement('stock_count', $item['quantity']);
            }

            $merchant = Merchant::findOrFail($merchantId);

            // Calculate distance and delivery fee
            $logistics = $this->calculateLogistics(
                $merchant->latitude,
                $merchant->longitude,
                $address->latitude,
                $address->longitude,
                $merchant->store_name,
                $merchant->city
            );

            // Fetch Financial Splits from dynamic settings
            $merchantRate = $merchant->commission_rate ?? PlatformSetting::get('merchant_commission_rate', 0.05);
            $riderRate = PlatformSetting::get('rider_commission_rate', 0.05);
            $convenienceFee = PlatformSetting::get('convenience_fee', 0);

            $merchantCommission = $subtotal * $merchantRate;
            $riderCommission = $logistics['delivery_fee'] * $riderRate;
            $platformFee = $merchantCommission + $riderCommission + $convenienceFee;

            $order = Order::create([
                'order_number' => 'PAT-' . strtoupper(Str::random(6)),
                'customer_id' => $user->id,
                'address_id' => $data['address_id'],
                'status' => 'pending_payment',
                'subtotal' => $subtotal,
                'delivery_fee' => $logistics['delivery_fee'],
                'platform_fee' => $platformFee,
                'total' => $subtotal + $logistics['delivery_fee'] + $convenienceFee,
                'payment_method' => $data['payment_method'],
                'payment_status' => 'pending',
                'customer_notes' => $data['customer_notes'] ?? null,
                'placed_at' => now(),
                'pickup_latitude' => $merchant->latitude,
                'pickup_longitude' => $merchant->longitude,
                'dropoff_latitude' => $address->latitude,
                'dropoff_longitude' => $address->longitude,
                'estimated_distance_km' => $logistics['distance'],
                'estimated_duration_minutes' => $logistics['duration'],
            ]);

            foreach ($orderItemsData as $item) {
                $order->orderItems()->create($item);
            }

            return $order;
        });
    }

    protected function calculateLogistics($pLat, $pLng, $dLat, $dLng, $storeName, $city = null)
    {
        $distance = 0;
        $duration = 25;

        if ($pLat && $pLng && $dLat && $dLng) {
            $route = $this->osm->getRoute($pLat, $pLng, $dLat, $dLng);
            if ($route) {
                $distance = $route['distance_km'];
                $duration = ceil($route['travel_time_seconds'] / 60) + 10;
            } else {
                // Fallback Haversine
                $distance = $this->haversine($pLat, $pLng, $dLat, $dLng);
                $duration = ceil($distance * 3) + 15;
            }
        }

        // Fetch pricing rule based on city/zone
        $rule = DeliveryPricingRule::where('zone_name', $city)
            ->where('is_active', true)
            ->first() ?? DeliveryPricingRule::where('is_active', true)->first();

        $baseFee = $rule ? $rule->base_fee : 2000;
        $perKmFee = $rule ? $rule->per_km_fee : 500;
        $maxDistance = $rule ? $rule->max_distance : 15;
        $surgeMultiplier = $rule ? $rule->surge_multiplier : 1.0;

        if ($distance > $maxDistance) {
            throw new \Exception("Delivery distance ({$distance}km) exceeds the maximum allowed limit for this zone ({$maxDistance}km).");
        }

        $fee = round(($baseFee + ($distance * $perKmFee)) * $surgeMultiplier, 2);

        if ($storeName === 'Global Simulation Store') {
            $fee = min($fee, 2000);
        }

        return ['distance' => $distance, 'duration' => $duration, 'delivery_fee' => $fee];
    }

    public function haversine($lat1, $lon1, $lat2, $lon2)
    {
        $earthRadius = 6371;
        $dLat = deg2rad($lat2 - $lat1);
        $dLon = deg2rad($lon2 - $lon1);
        $a = sin($dLat/2) * sin($dLat/2) + cos(deg2rad($lat1)) * cos(deg2rad($lat2)) * sin($dLon/2) * sin($dLon/2);
        return $earthRadius * (2 * atan2(sqrt($a), sqrt(1-$a)));
    }
}
