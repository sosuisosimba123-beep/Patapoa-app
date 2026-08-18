<?php

namespace Tests\Feature;

use App\Models\User;
use App\Models\Merchant;
use App\Models\Category;
use App\Models\MasterProduct;
use App\Models\Product;
use App\Services\AiStandardizationService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class ProductEnrichmentTest extends TestCase
{
    use RefreshDatabase;

    protected User $user;
    protected Merchant $merchant;

    protected function setUp(): void
    {
        parent::setUp();

        $this->user = User::factory()->create(['user_type' => 'merchant']);
        $this->merchant = Merchant::factory()->create(['user_id' => $this->user->id]);

        Category::factory()->create(['slug' => 'beverages', 'name' => 'Beverages']);
    }

    /** @test */
    public function it_enriches_manual_listing_using_ai()
    {
        $barcode = '6001087304192';
        $highQualityImage = 'https://gemini-assets.com/coke_pro_shot.jpg';

        // Mock Gemini
        $this->mock(AiStandardizationService::class, function ($mock) use ($highQualityImage) {
            $mock->shouldReceive('standardizeProduct')->once()->andReturn([
                'product_name' => 'Coca-Cola Classic',
                'brand' => 'Coca-Cola',
                'category_slug' => 'beverages',
                'size' => '500ml',
                'high_quality_image_url' => $highQualityImage,
                'is_valid' => true
            ]);
        });

        $payload = [
            'name' => 'Coke',
            'barcode' => $barcode,
            'price' => 1500,
            'stock_count' => 10,
        ];

        $response = $this->actingAs($this->user)
            ->postJson('/api/v1/merchant/products', $payload);

        $response->assertStatus(201);

        $this->assertDatabaseHas('products', [
            'name' => 'Coca-Cola Classic',
            'brand' => 'Coca-Cola',
        ]);

        $this->assertDatabaseHas('master_products', [
            'barcode' => $barcode,
            'primary_image_url' => $highQualityImage,
        ]);

        $product = Product::first();
        $this->assertEquals([$highQualityImage], $product->images);
    }

    /** @test */
    public function it_reuses_cached_master_product_for_subsequent_listings()
    {
        $barcode = '123456789';

        // Create an existing MasterProduct
        $master = MasterProduct::create([
            'name' => 'Cached Product',
            'barcode' => $barcode,
            'category_id' => Category::first()->id,
            'primary_image_url' => 'https://cached.com/image.jpg',
            'slug' => 'cached-product',
        ]);

        // Mock services - they should NOT be called for enrichment if MasterProduct exists
        $this->mock(AiStandardizationService::class, function ($mock) {
            $mock->shouldReceive('standardizeProduct')->never();
        });

        $payload = [
            'barcode' => $barcode,
            'price' => 2000,
            'stock_count' => 5,
        ];

        $response = $this->actingAs($this->user)
            ->postJson('/api/v1/merchant/products', $payload);

        $response->assertStatus(201);

        $this->assertDatabaseHas('products', [
            'master_product_id' => $master->id,
            'name' => 'Cached Product',
        ]);

        $this->assertCount(1, MasterProduct::all());
    }

    /** @test */
    public function it_falls_back_gracefully_when_ai_fails()
    {
        $this->mock(AiStandardizationService::class, function ($mock) {
            $mock->shouldReceive('standardizeProduct')->andReturn(null);
        });

        $payload = [
            'name' => 'Unknown Item',
            'price' => 500,
            'stock_count' => 100,
            'category_id' => Category::first()->id,
        ];

        $response = $this->actingAs($this->user)
            ->postJson('/api/v1/merchant/products', $payload);

        $response->assertStatus(201);

        // Should still be created with the name provided manually
        $this->assertDatabaseHas('products', [
            'name' => 'Unknown Item',
        ]);
    }
}
