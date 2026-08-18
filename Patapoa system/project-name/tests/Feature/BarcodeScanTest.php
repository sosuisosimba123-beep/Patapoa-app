<?php

namespace Tests\Feature;

use App\Models\User;
use App\Models\Category;
use App\Models\MasterProduct;
use App\Services\AiStandardizationService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class BarcodeScanTest extends TestCase
{
    use RefreshDatabase;

    protected User $user;

    protected function setUp(): void
    {
        parent::setUp();
        $this->user = User::factory()->create(['user_type' => 'merchant']);
        Category::factory()->create(['id' => 1, 'slug' => 'other', 'name' => 'Other']);
    }

    /** @test */
    public function it_returns_cached_master_product_instantly_on_scan()
    {
        $barcode = '1234567890';
        $master = MasterProduct::create([
            'name' => 'Existing Master',
            'barcode' => $barcode,
            'category_id' => 1,
            'primary_image_url' => 'https://example.com/cached.jpg',
            'slug' => 'existing-master',
        ]);

        // AI Service should NEVER be called if cached
        $this->mock(AiStandardizationService::class, function ($mock) {
            $mock->shouldReceive('standardizeProduct')->never();
        });

        $response = $this->actingAs($this->user)
            ->postJson('/api/v1/products/scan', ['barcode' => $barcode]);

        $response->assertStatus(200)
            ->assertJsonPath('data.is_cached', true)
            ->assertJsonPath('data.name', 'Existing Master');
    }

    /** @test */
    public function it_triggers_ai_enrichment_for_new_barcodes()
    {
        $barcode = '9876543210';
        $hqImage = 'https://ai.com/pro.jpg';

        $this->mock(AiStandardizationService::class, function ($mock) use ($hqImage) {
            $mock->shouldReceive('standardizeProduct')->once()->andReturn([
                'product_name' => 'AI Discovered Product',
                'brand' => 'AI Brand',
                'category_slug' => 'other',
                'size' => '1L',
                'high_quality_image_url' => $hqImage,
                'is_valid' => true
            ]);
        });

        $response = $this->actingAs($this->user)
            ->postJson('/api/v1/products/scan', ['barcode' => $barcode]);

        $response->assertStatus(200)
            ->assertJsonPath('data.is_cached', false)
            ->assertJsonPath('data.name', 'AI Discovered Product')
            ->assertJsonPath('data.image_url', $hqImage);

        $this->assertDatabaseHas('master_products', [
            'barcode' => $barcode,
            'name' => 'AI Discovered Product',
        ]);
    }

    /** @test */
    public function it_returns_404_when_product_cannot_be_found_or_enriched_by_ai()
    {
        $this->mock(AiStandardizationService::class, function ($mock) {
            $mock->shouldReceive('standardizeProduct')->andReturn(null);
        });

        $response = $this->actingAs($this->user)
            ->postJson('/api/v1/products/scan', ['barcode' => 'invalid']);

        $response->assertStatus(404);
    }
}
