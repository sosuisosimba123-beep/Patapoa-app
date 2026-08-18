<?php

namespace App\Services;

use App\Models\Order;
use App\Models\DeliveryPartner;
use Illuminate\Support\Facades\DB;

class LogisticsService
{
    /**
     * Find the best available delivery partners for a specific order.
     * Uses spatial indexing to find partners within a radius and filters by status.
     */
    public function findNearbyPartners(Order $order, float $radiusKm = 10.0, int $limit = 5)
    {
        // Reference point: Order Pickup Location
        $lat = $order->pickup_latitude;
        $lng = $order->pickup_longitude;

        if (!$lat || !$lng) {
            return collect();
        }

        $query = DeliveryPartner::query()
            ->where('is_online', true)
            ->where('is_verified', true)
            ->where('is_on_delivery', false)
            ->select('delivery_partners.*');

        if (DB::getDriverName() === 'sqlite') {
            // Haversine fallback for SQLite (tests)
            $query->selectRaw(
                "(6371 * acos(cos(radians(?)) * cos(radians(current_latitude)) * cos(radians(current_longitude) - radians(?)) + sin(radians(?)) * sin(radians(current_latitude)))) AS distance_km",
                [$lat, $lng, $lat]
            )
            ->whereRaw(
                "(6371 * acos(cos(radians(?)) * cos(radians(current_latitude)) * cos(radians(current_longitude) - radians(?)) + sin(radians(?)) * sin(radians(current_latitude)))) <= ?",
                [$lat, $lng, $lat, $radiusKm]
            );
        } else {
            $query->selectRaw(
                "ST_Distance_Sphere(location, ST_PointFromText(CONCAT('POINT(', ?, ' ', ?, ')'))) / 1000 AS distance_km",
                [$lng, $lat]
            )
            ->whereRaw(
                "ST_Distance_Sphere(location, ST_PointFromText(CONCAT('POINT(', ?, ' ', ?, ')'))) <= ?",
                [$lng, $lat, $radiusKm * 1000]
            );
        }

        return $query->orderBy('distance_km', 'asc')
            ->limit($limit)
            ->get();
    }

    /**
     * Automatically assign an order to the absolute nearest available partner.
     */
    public function autoAssign(Order $order)
    {
        $partners = $this->findNearbyPartners($order, 15, 1);

        if ($partners->isNotEmpty()) {
            $bestPartner = $partners->first();

            $order->update([
                'delivery_partner_id' => $bestPartner->id,
                'status' => 'rider_assigned'
            ]);

            $bestPartner->update(['is_on_delivery' => true]);

            return $bestPartner;
        }

        return null;
    }
}
