<?php

namespace Tests\Feature;

use App\Models\Merchant;
use Database\Seeders\MerchantSpatialSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class MerchantSpatialTest extends TestCase
{
    use RefreshDatabase;

    /** @test */
    public function it_correctly_filters_merchants_within_a_spatial_radius()
    {
        // 1. Seed the test data (Moshi area)
        $this->seed(MerchantSpatialSeeder::class);

        // Reference Point: Moshi Clock Tower
        $moshiLat = -3.3349;
        $moshiLng = 37.3404;

        // 2. Query for merchants within 15km
        $nearbyMerchants = Merchant::withinRadius($moshiLat, $moshiLng, 15)
            ->withDistance($moshiLat, $moshiLng)
            ->orderBy('distance_km', 'asc')
            ->get();

        // 3. Assertions
        // Based on seeder: Moshi Central (~0.2km) and KCMC Area (~4km) should be in.
        // Himo (25km) and Arusha (80km) should be out.
        $this->assertCount(2, $nearbyMerchants);

        $this->assertEquals('Moshi Central Market Vendor', $nearbyMerchants[0]->store_name);
        $this->assertEquals('KCMC Area Grocery', $nearbyMerchants[1]->store_name);

        // Verify distance calculation is accurate (km)
        $this->assertLessThan(1, $nearbyMerchants[0]->distance_km);
        $this->assertGreaterThan(2, $nearbyMerchants[1]->distance_km);
        $this->assertLessThan(6, $nearbyMerchants[1]->distance_km);
    }

    /** @test */
    public function it_includes_distant_merchants_when_radius_is_expanded()
    {
        $this->seed(MerchantSpatialSeeder::class);

        $moshiLat = -3.3349;
        $moshiLng = 37.3404;

        // Query for 30km radius (should include Himo Town)
        $merchants = Merchant::withinRadius($moshiLat, $moshiLng, 30)->get();

        $this->assertCount(3, $merchants);
        $this->assertTrue($merchants->contains('store_name', 'Himo Town Store'));
    }

    /** @test */
    public function it_correctly_calculates_distances_for_all_merchants()
    {
        $this->seed(MerchantSpatialSeeder::class);

        $moshiLat = -3.3349;
        $moshiLng = 37.3404;

        $merchants = Merchant::withDistance($moshiLat, $moshiLng)
            ->where('city', 'Arusha')
            ->first();

        // Arusha should be roughly 75-85km from Moshi
        $this->assertGreaterThan(70, $merchants->distance_km);
        $this->assertLessThan(90, $merchants->distance_km);
    }
}
