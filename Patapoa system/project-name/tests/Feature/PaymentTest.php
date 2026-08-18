<?php

namespace Tests\Feature;

use App\Models\Order;
use App\Models\User;
use App\Models\Wallet;
use App\Models\Address;
use App\Services\ClickPesaService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use Mockery;

class PaymentTest extends TestCase
{
    use RefreshDatabase;

    public function test_customer_can_initiate_payment()
    {
        $user = User::factory()->create([
            'user_type' => 'customer',
            'phone' => '255712345678'
        ]);

        $address = Address::create([
            'user_id' => $user->id,
            'label' => 'Home',
            'recipient_name' => $user->name,
            'phone' => $user->phone,
            'address_line_1' => 'Street 1',
            'city' => 'DSM',
            'latitude' => -6.123,
            'longitude' => 39.123,
        ]);

        $order = Order::create([
            'customer_id' => $user->id,
            'address_id' => $address->id,
            'total' => 10000,
            'status' => 'placed',
            'order_number' => 'PAT-123',
            'subtotal' => 9000,
            'delivery_fee' => 500,
            'platform_fee' => 500,
            'payment_status' => 'pending',
            'payment_method' => 'mpesa'
        ]);

        $this->actingAs($user);

        // Mock Clickpesa
        $mock = Mockery::mock(ClickPesaService::class);
        $mock->shouldReceive('initiateUSSD')->once()->andReturn(['success' => true, 'transaction_id' => 'test_123']);
        $this->app->instance(ClickPesaService::class, $mock);

        $response = $this->postJson('/api/v1/payments/initiate', [
            'order_id' => $order->id,
            'payment_method' => 'mpesa',
        ]);

        $response->assertStatus(200)
            ->assertJsonPath('message', 'Payment initiated via Clickpesa');
    }

    public function test_rider_can_request_payout()
    {
        $user = User::factory()->create([
            'user_type' => 'rider',
            'phone' => '255712345679'
        ]);

        $wallet = Wallet::create([
            'user_id' => $user->id,
            'balance' => 50000,
            'wallet_type' => 'rider'
        ]);

        $this->actingAs($user);

        // Mock Clickpesa
        $mock = Mockery::mock(ClickPesaService::class);
        $mock->shouldReceive('payout')->once()->andReturn(['success' => true]);
        $this->app->instance(ClickPesaService::class, $mock);

        $response = $this->postJson('/api/v1/delivery-partner/payout/request', [
            'amount' => 10000,
            'phone' => '255712345679',
            'provider' => 'mpesa',
        ]);

        $response->assertStatus(200);
        $this->assertEquals(40000, $wallet->fresh()->balance);
    }
}
