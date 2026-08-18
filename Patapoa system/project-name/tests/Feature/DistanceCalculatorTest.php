<?php

namespace Tests\Feature;

use App\Models\Merchant;
use App\Models\User;
use App\Services\OrderService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class DistanceCalculatorTest extends TestCase
{
    use RefreshDatabase;

    /** @test */
    public function it_calculates_moshi_coordinate_distances_accurately()
    {
        $service = app(OrderService::class);

        // Moshi Points
        $moshiClockTower = ['lat' => -3.3349, 'lng' => 37.3404];
        $kcmcHospital = ['lat' => -3.3150, 'lng' => 37.3280];

        // Known distance between these points is approx 2.6km
        $distance = $service->haversine(
            $moshiClockTower['lat'], $moshiClockTower['lng'],
            $kcmcHospital['lat'], $kcmcHospital['lng']
        );

        // Assert accuracy within 100 meters (0.1km)
        $this->assertEqualsWithDelta(2.6, $distance, 0.1);
    }

    /** @test */
    public function it_returns_zero_for_identical_coordinates()
    {
        $service = app(OrderService::class);

        $lat = -3.3349;
        $lng = 37.3404;

        $distance = $service->haversine($lat, $lng, $lat, $lng);

        $this->assertEquals(0, $distance);
    }

    /** @test */
    public function it_matches_database_spatial_calculations()
    {
        $user = User::factory()->create();
        $merchant = Merchant::create([
            'user_id' => $user->id,
            'store_name' => 'KCMC Grocery',
            'latitude' => -3.3150,
            'longitude' => 37.3280,
            'address' => 'KCMC Area',
            'city' => 'Moshi',
            'is_verified' => true,
        ]);

        $moshiLat = -3.3349;
        $moshiLng = 37.3404;

        // Query using MySQL Spatial ST_Distance_Sphere
        $dbMerchant = Merchant::withDistance($moshiLat, $moshiLng)->first();

        // Haversine calculation in PHP
        $haversineDistance = app(OrderService::class)->haversine(
            $moshiLat, $moshiLng,
            $merchant->latitude, $merchant->longitude
        );

        // Both should be extremely close (usually within a few meters)
        $this->assertEqualsWithDelta($haversineDistance, $dbMerchant->distance_km, 0.05);
    }

    /** @test */
    public function it_scales_correctly_for_long_distances()
    {
        $service = app(OrderService::class);

        // Moshi to Dar es Salaam (~440km straight line)
        $moshi = ['lat' => -3.3349, 'lng' => 37.3404];
        $dar = ['lat' => -6.7924, 'lng' => 39.2083];

        $distance = $service->haversine($moshi['lat'], $moshi['lng'], $dar['lat'], $dar['lng']);

        $this->assertGreaterThan(430, $distance);
        $this->assertLessThan(460, $distance);
    }
}
