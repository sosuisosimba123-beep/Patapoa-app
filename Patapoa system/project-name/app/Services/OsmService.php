<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Cache;

class OsmService
{
    protected $nominatimUrl = 'https://nominatim.openstreetmap.org';
    protected $osrmUrl = 'https://router.project-osrm.org';
    protected $breaker;

    public function __construct()
    {
        $this->breaker = new CircuitBreaker('osm', 10, 30);
    }

    /**
     * Calculate road distance and time between two points (OSRM)
     */
    public function getRoute(float $startLat, float $startLon, float $endLat, float $endLon)
    {
        return $this->breaker->execute(function () use ($startLat, $startLon, $endLat, $endLon) {
            $url = "{$this->osrmUrl}/route/v1/driving/{$startLon},{$startLat};{$endLon},{$endLat}?overview=full&geometries=geojson";

            $response = Http::get($url);

            if ($response->successful()) {
                $data = $response->json();
                if (!empty($data['routes'])) {
                    $route = $data['routes'][0];
                    return [
                        'distance_km' => $route['distance'] / 1000,
                        'travel_time_seconds' => (int) $route['duration'],
                        'geometry' => $route['geometry']['coordinates'] ?? []
                    ];
                }
            } else {
                Log::error('OSRM API Error', [
                    'status' => $response->status(),
                    'body' => $response->body()
                ]);
                throw new \Exception("OSRM API error: {$response->status()}");
            }
            return null;
        }, function (\Exception $e) {
            Log::warning("OSRM Fallback triggered: {$e->getMessage()}");
            return null;
        });
    }

    /**
     * Reverse geocode coordinates to address (Nominatim)
     * Includes caching to minimize redundant public requests.
     */
    public function reverseGeocode(float $lat, float $lon)
    {
        return $this->breaker->execute(function () use ($lat, $lon) {
            $cacheKey = "geo:{$lat}:{$lon}";

            return Cache::remember($cacheKey, 86400, function() use ($lat, $lon) {
                $url = "{$this->nominatimUrl}/reverse?lat={$lat}&lon={$lon}&format=json&addressdetails=1";

                $response = Http::withHeaders([
                    'User-Agent' => 'PatapoaBackend/1.0'
                ])->get($url);

                if ($response->successful()) {
                    $data = $response->json();
                    return $data['display_name'] ?? null;
                }

                throw new \Exception("Nominatim API error: {$response->status()}");
            });
        }, function (\Exception $e) {
            return "Address service currently offline";
        });
    }
}
