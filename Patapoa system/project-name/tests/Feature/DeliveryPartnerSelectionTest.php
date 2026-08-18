<?php

namespace Tests\Feature;

use App\Models\DeliveryPartner;
use App\Models\Merchant;
use App\Models\Order;
use App\Models\User;
use App\Models\Address;
use App\Services\LogisticsService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class DeliveryPartnerSelectionTest extends TestCase
{
    use RefreshDatabase;

    /** @test */
    public function it_selects_the_nearest_available_verified_rider()
    {
        $logistics = new LogisticsService();

        // 1. Create a Merchant in Moshi Central
        $merchantUser = User::factory()->create(['user_type' => 'merchant']);
        $merchant = Merchant::create([
            'user_id' => $merchantUser->id,
            'store_name' => 'Moshi Market',
            'latitude' => -3.3349, // Moshi Clock Tower
            'longitude' => 37.3404,
            'address' => 'Central Moshi',
            'city' => 'Moshi',
            'is_verified' => true,
        ]);

        // 2. Create an Order from this Merchant
        $customer = User::factory()->create(['user_type' => 'customer']);
        $address = Address::factory()->create(['user_id' => $customer->id]);

        $order = Order::create([
            'order_number' => 'PAT-TEST-1',
            'customer_id' => $customer->id,
            'address_id' => $address->id,
            'status' => 'placed',
            'pickup_latitude' => $merchant->latitude,
            'pickup_longitude' => $merchant->longitude,
            'dropoff_latitude' => -3.3150,
            'dropoff_longitude' => 37.3280,
            'subtotal' => 3000,
            'delivery_fee' => 2000,
            'total' => 5000,
            'payment_status' => 'paid',
        ]);

        // 3. Seed Riders

        // Rider A: Closest (200m) but OFFLINE
        DeliveryPartner::factory()->create([
            'is_online' => false,
            'current_latitude' => -3.3360,
            'current_longitude' => 37.3410,
        ]);

        // Rider B: Very close (500m) but BUSY (on delivery)
        DeliveryPartner::factory()->create([
            'is_online' => true,
            'is_on_delivery' => true,
            'current_latitude' => -3.3380,
            'current_longitude' => 37.3420,
        ]);

        // Rider C: Closest Available (~1km) but UNVERIFIED
        DeliveryPartner::factory()->create([
            'is_online' => true,
            'is_verified' => false,
            'is_on_delivery' => false,
            'current_latitude' => -3.3400,
            'current_longitude' => 37.3450,
        ]);

        // Rider D: Optimal Choice (~3km) AVAILABLE & VERIFIED
        $optimalRider = DeliveryPartner::factory()->create([
            'is_online' => true,
            'is_verified' => true,
            'is_on_delivery' => false,
            'current_latitude' => -3.3150,
            'current_longitude' => 37.3280,
        ]);

        // Rider E: Further away (~10km) AVAILABLE & VERIFIED
        DeliveryPartner::factory()->create([
            'is_online' => true,
            'is_verified' => true,
            'is_on_delivery' => false,
            'current_latitude' => -3.3850,
            'current_longitude' => 37.5500,
        ]);

        // 4. Run Selection
        $assignedRider = $logistics->autoAssign($order);

        // 5. Assertions
        $this->assertNotNull($assignedRider);
        $this->assertEquals($optimalRider->id, $assignedRider->id);

        $order->refresh();
        $this->assertEquals('rider_assigned', $order->status);
        $this->assertEquals($optimalRider->id, $order->delivery_partner_id);

        $optimalRider->refresh();
        $this->assertTrue($optimalRider->is_on_delivery);
    }

    /** @test */
    public function it_gracefully_handles_no_available_riders()
    {
        $logistics = new LogisticsService();

        $customer = User::factory()->create();
        $address = Address::factory()->create(['user_id' => $customer->id]);

        $order = Order::create([
            'order_number' => 'PAT-TEST-EMPTY',
            'pickup_latitude' => -3.3349,
            'pickup_longitude' => 37.3404,
            'customer_id' => $customer->id,
            'address_id' => $address->id,
            'status' => 'placed',
            'subtotal' => 800,
            'delivery_fee' => 200,
            'total' => 1000,
        ]);

        // No riders seeded at all or all offline
        DeliveryPartner::factory()->count(3)->create(['is_online' => false]);

        $assignedRider = $logistics->autoAssign($order);

        $this->assertNull($assignedRider);

        $order->refresh();
        $this->assertNotEquals('rider_assigned', $order->status);
    }
}
