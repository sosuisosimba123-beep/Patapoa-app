<?php

namespace Tests\Feature;

use App\Models\User;
use App\Models\Address;
use App\Models\Product;
use App\Models\Order;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Str;
use Tests\TestCase;

class IdempotencyTest extends TestCase
{
    use RefreshDatabase;

    protected User $user;

    protected function setUp(): void
    {
        parent::setUp();

        // Create a verified user for testing
        $this->user = User::factory()->create([
            'phone' => '255700000000',
            'user_type' => 'customer',
            'email_verified_at' => now(),
        ]);

        Cache::flush();
    }

    /** @test */
    public function it_returns_cached_response_for_duplicate_idempotency_keys()
    {
        $idempotencyKey = Str::uuid()->toString();
        $payload = [
            'label' => 'Home',
            'recipient_name' => 'John Doe',
            'phone' => '255712345678',
            'address_line_1' => '123 Test Street',
            'city' => 'Dar es Salaam',
            'latitude' => -6.7924,
            'longitude' => 39.2083,
        ];

        // 1. First Request - Should be a CACHE MISS
        $response1 = $this->actingAs($this->user)
            ->withHeader('X-Idempotency-Key', $idempotencyKey)
            ->postJson('/api/v1/addresses', $payload);

        $response1->assertStatus(201);
        $this->assertCount(1, Address::all());
        $this->assertNull($response1->headers->get('X-Idempotency-Cache'));

        // 2. Second Request (Duplicate) - Should be a CACHE HIT
        $response2 = $this->actingAs($this->user)
            ->withHeader('X-Idempotency-Key', $idempotencyKey)
            ->postJson('/api/v1/addresses', $payload);

        $response2->assertStatus(201);

        // Critically: No new database entry should be created
        $this->assertCount(1, Address::all());

        // Check for the HIT header
        $this->assertEquals('HIT', $response2->headers->get('X-Idempotency-Cache'));

        // Ensure content is identical
        $this->assertEquals($response1->json(), $response2->json());
    }

    /** @test */
    public function it_allows_different_keys_to_create_new_records()
    {
        $payload = [
            'label' => 'Work',
            'recipient_name' => 'John Doe',
            'phone' => '255712345678',
            'address_line_1' => 'New Street',
            'city' => 'Arusha',
            'latitude' => -3.3731,
            'longitude' => 36.6852,
        ];

        // Request with Key A
        $this->actingAs($this->user)
            ->withHeader('X-Idempotency-Key', 'KEY-A')
            ->postJson('/api/v1/addresses', $payload)
            ->assertStatus(201);

        // Request with Key B (Same payload, different key)
        $this->actingAs($this->user)
            ->withHeader('X-Idempotency-Key', 'KEY-B')
            ->postJson('/api/v1/addresses', $payload)
            ->assertStatus(201);

        // Should have 2 records
        $this->assertCount(2, Address::all());
    }

    /** @test */
    public function it_handles_requests_without_idempotency_keys_normally()
    {
        $payload = [
            'label' => 'Other',
            'recipient_name' => 'John Doe',
            'phone' => '255712345678',
            'address_line_1' => 'No Key Street',
            'city' => 'Mwanza',
            'latitude' => -2.5167,
            'longitude' => 32.9000,
        ];

        // Send twice without headers
        $this->actingAs($this->user)->postJson('/api/v1/addresses', $payload)->assertStatus(201);
        $this->actingAs($this->user)->postJson('/api/v1/addresses', $payload)->assertStatus(201);

        // Should create two records (Normal behavior)
        $this->assertCount(2, Address::all());
    }

    /** @test */
    public function it_does_not_cache_failed_responses()
    {
        $idempotencyKey = 'FAILURE-KEY';

        // Missing required field 'label' to trigger 422
        $payload = [
            'city' => 'Failed City',
        ];

        // First attempt - fails validation
        $this->actingAs($this->user)
            ->withHeader('X-Idempotency-Key', $idempotencyKey)
            ->postJson('/api/v1/addresses', $payload)
            ->assertStatus(422);

        // Second attempt - if we fix the payload but keep the key, it should succeed
        // because the previous 422 shouldn't have been cached.
        $payload = [
            'label' => 'Home',
            'recipient_name' => 'John Doe',
            'phone' => '255712345678',
            'address_line_1' => 'Fixed Street',
            'city' => 'Fixed City',
            'latitude' => 0,
            'longitude' => 0,
        ];

        $response = $this->actingAs($this->user)
            ->withHeader('X-Idempotency-Key', $idempotencyKey)
            ->postJson('/api/v1/addresses', $payload);

        $response->assertStatus(201);
        $this->assertNull($response->headers->get('X-Idempotency-Cache'));
    }

    /** @test */
    public function it_is_applied_to_the_order_creation_route()
    {
        $idempotencyKey = 'ORDER-KEY';

        // Create actual dependency data so Validator passes
        $address = Address::factory()->create(['user_id' => $this->user->id]);
        $product = Product::factory()->create();

        // Mocking the OrderService to avoid complex setup
        $this->mock(\App\Services\OrderService::class, function ($mock) {
            $mock->shouldReceive('createOrder')->once()->andReturn(new Order([
                'id' => 999,
                'order_number' => 'PAT-TEST'
            ]));
        });

        $payload = [
            'address_id' => $address->id,
            'items' => [['product_id' => $product->id, 'quantity' => 1]],
            'payment_method' => 'mpesa',
        ];

        // 1. First Request
        $this->actingAs($this->user)
            ->withHeader('X-Idempotency-Key', $idempotencyKey)
            ->postJson('/api/v1/customer/orders', $payload)
            ->assertStatus(201);

        // 2. Second Request - Should be HIT from Cache
        $response = $this->actingAs($this->user)
            ->withHeader('X-Idempotency-Key', $idempotencyKey)
            ->postJson('/api/v1/customer/orders', $payload);

        $response->assertStatus(201);
        $this->assertEquals('HIT', $response->headers->get('X-Idempotency-Cache'));
    }
}
