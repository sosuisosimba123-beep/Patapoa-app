<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Product;
use App\Models\SearchLog;
use App\Models\Waitlist;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;
use App\Services\AiStandardizationService;
use App\Services\ProductEnrichmentService;

class ProductController extends Controller
{
    protected $enrichment;

    public function __construct(ProductEnrichmentService $enrichment)
    {
        $this->enrichment = $enrichment;
    }

    public function index(Request $request)
    {
        $cacheKey = 'products:' . md5($request->fullUrl());

        $result = $this->remember($cacheKey, function () use ($request) {
            $lat = $request->get('latitude');
            $lng = $request->get('longitude');

            $query = Product::with(['merchant', 'masterProduct', 'secondaryCategory'])
                ->where('is_available', true)
                ->whereHas('merchant', function($q) {
                    $q->where(function($sq) {
                        $sq->where('is_online', true)
                          ->where('is_verified', true);
                    })
                    // Always show the simulation store even if it's "offline" or "unverified" for testing
                    ->orWhere('store_name', 'Global Simulation Store');
                });

            // 1. Search Logic
            $heroData = null;
            if ($request->has('q') && !empty($request->q)) {
                $q = $request->q;

                // Find hero master product
                $heroData = \App\Models\MasterProduct::where(function($query) use ($q) {
                        $query->where('name', 'like', "%$q%")
                              ->orWhereJsonContains('search_tags', $q);
                    })
                    ->orderByRaw("CASE WHEN brand = 'Generic' THEN 0 ELSE 1 END")
                    ->first();

                $query->where(function($sub) use ($q) {
                    $sub->whereHas('masterProduct', function($mq) use ($q) {
                        $mq->where('name', 'like', "%$q%")
                           ->orWhereJsonContains('search_tags', $q);
                    })->orWhere('name', 'like', "%$q%")
                      // ALWAYS include simulation products if they exist, so the user can always find them
                      ->orWhereHas('merchant', function($mq) {
                          $mq->where('store_name', 'Global Simulation Store');
                      });
                });
            }

            if ($request->has('secondary_category_id')) {
                $query->where('secondary_category_id', $request->secondary_category_id);
            }

            if ($request->has('primary_category_id')) {
                $query->whereHas('secondaryCategory', function($q) use ($request) {
                    $q->where('primary_category_id', $request->primary_category_id);
                });
            }

            // 2. Distance Sorting & Filtering Logic (Spatial Index)
            if ($lat && $lng) {
                $query->select('products.*')
                    ->join('merchants', 'products.merchant_id', '=', 'merchants.id')
                    ->where(function($q) use ($lat, $lng) {
                        $q->withinRadius($lat, $lng, 15)
                          ->orWhere('merchants.store_name', 'Global Simulation Store');
                    });

                if (\Illuminate\Support\Facades\DB::getDriverName() === 'sqlite') {
                    $query->selectRaw(
                        "(6371 * acos(cos(radians(?)) * cos(radians(merchants.latitude)) * cos(radians(merchants.longitude) - radians(?)) + sin(radians(?)) * sin(radians(merchants.latitude)))) AS distance",
                        [$lat, $lng, $lat]
                    );
                } else {
                    $query->selectRaw(
                        "ST_Distance_Sphere(merchants.location, ST_GeomFromText('POINT(? ?)', 4326)) / 1000 AS distance",
                        [$lng, $lat]
                    );
                }

                $query->orderBy('products.is_featured', 'desc')
                    ->orderBy('distance', 'asc');
            } else {
                $query->orderBy('is_featured', 'desc')
                    ->orderBy('products.created_at', 'desc');
            }

            $products = $this->paginateQuery($query, $request, 20, 100);

            // Log the search and handle automatic waitlisting
            if ($lat && $lng) {
                try {
                    // Check if there are any merchants at all within 15km using spatial index
                    $merchantsNearby = \App\Models\Merchant::where('store_name', 'Global Simulation Store')
                        ->where('is_online', true)
                        ->exists()
                        || \App\Models\Merchant::where('is_verified', true)
                            ->withinRadius($lat, $lng, 15)
                            ->exists();

                    if (!$merchantsNearby && $request->user()) {
                        // Automatically add/update waitlist if out of range
                        Waitlist::updateOrCreate(
                            ['user_id' => $request->user()->id],
                            [
                                'email' => $request->user()->email,
                                'phone' => $request->user()->phone,
                                'latitude' => $lat,
                                'longitude' => $lng,
                                'city' => $request->get('city', 'Current Location'),
                                'requested_product' => $request->q ?? $heroData?->name
                            ]
                        );
                    }

                    if ($request->has('q')) {
                        SearchLog::create([
                            'user_id' => $request->user()?->id,
                            'query' => $request->q,
                            'latitude' => $lat,
                            'longitude' => $lng,
                            'has_results' => $products->total() > 0,
                            'is_serviceable' => $merchantsNearby,
                        ]);
                    }
                } catch (\Exception $e) {
                    \Log::error('Search/Waitlist Logging Failed: ' . $e->getMessage());
                }
            }

            return [
                'hero_product' => $heroData,
                'products' => $products,
                'merchants_nearby' => ($products->total() > 0) || ($merchantsNearby ?? true),
            ];
        }, 1);

        return $this->successResponse($result, 'Products retrieved successfully');
    }

    public function show(Request $request, $id)
    {
        $cacheKey = "product:{$id}";

        $product = $this->remember($cacheKey, function () use ($request, $id) {
            $query = Product::with(['merchant:id,store_name,address,city,rating', 'secondaryCategory.primaryCategory']);

            // Selective field loading for list views
            if ($request->has('fields')) {
                $fields = array_map('trim', explode(',', $request->get('fields')));
                $query->select(array_merge(['id', 'merchant_id', 'secondary_category_id'], $fields));
            }

            return $query->findOrFail($id);
        }, 60); // 60-second cache for individual product

        return $this->successResponse($product, 'Product retrieved successfully');
    }

    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'master_product_id' => 'nullable|integer',
            'secondary_category_id' => 'nullable|exists:secondary_categories,id',
            'name' => 'required_without_all:master_product_id,barcode|string|max:255',
            'brand' => 'nullable|string|max:255',
            'unit' => 'nullable|string|max:100',
            'barcode' => 'nullable|string|max:50',
            'price' => 'required|numeric|min:0',
            'stock_count' => 'required|integer|min:0',
            'image_url' => 'nullable|string',
            'description' => 'nullable|string',
            'is_available' => 'boolean',
            'is_custom' => 'boolean',
        ]);

        if ($validator->fails()) {
            return $this->errorResponse('Validation failed', 422, $validator->errors()->toArray());
        }

        $merchant = $request->user()->merchant;
        $masterId = $request->master_product_id;
        $secondaryCategoryId = $request->secondary_category_id;
        $name = $request->name;
        $unit = $request->unit ?? $request->description_unit;
        $imageUrl = $request->image_url;
        $brand = $request->brand;

        // Task: Enrichment for new products (not from master)
        if (!$masterId) {
            // Check if we already have a MasterProduct with this barcode
            if ($request->barcode) {
                $master = \App\Models\MasterProduct::where('barcode', $request->barcode)->first();
                if ($master) {
                    $masterId = $master->id;
                }
            }

            if (!$masterId) {
                // Enrich using external APIs (OFF/Gemini)
                $enriched = $this->enrichment->enrich($name ?? '', $request->barcode);

                // Prioritize enriched data
                $name = $enriched['name'] ?? $name;
                $brand = $brand ?? $enriched['brand'];
                $imageUrl = $imageUrl ?? $enriched['image_url'];
                $unit = $unit ?? $enriched['size'];

                // Create a MasterProduct for caching/future reuse
                if ($request->barcode || $name) {
                    $master = \App\Models\MasterProduct::create([
                        'name' => $name,
                        'brand' => $brand,
                        'barcode' => $request->barcode,
                        'secondary_category_id' => $secondaryCategoryId,
                        'primary_image_url' => $imageUrl ?? '',
                        'slug' => \Illuminate\Support\Str::slug($name . '-' . ($request->barcode ?? uniqid())),
                    ]);
                    $masterId = $master->id;
                }
            }
        }

        // If masterId is available, ensure we sync basic info if missing
        if ($masterId && !$name) {
            $master = \App\Models\MasterProduct::find($masterId);
            if ($master) {
                $name = $name ?? $master->name;
                $imageUrl = $imageUrl ?? $master->primary_image_url;
                $brand = $brand ?? $master->brand;
                $secondaryCategoryId = $secondaryCategoryId ?? $master->secondary_category_id;
            }
        }

        $product = Product::create([
            'merchant_id' => $merchant->id,
            'master_product_id' => $masterId,
            'secondary_category_id' => $secondaryCategoryId,
            'name' => $name,
            'brand' => $brand,
            'unit' => $unit,
            'price' => $request->price,
            'stock_count' => $request->stock_count,
            'description' => $request->description,
            'images' => $imageUrl ? [$imageUrl] : null,
            'is_available' => $request->is_available ?? true,
            'is_custom' => $request->is_custom ?? ($masterId == null),
        ]);

        // Clear product listing cache
        $this->globalCacheFlush();

        return $this->successResponse($product->load(['masterProduct', 'secondaryCategory']), 'Product listed successfully', 201);
    }

    public function update(Request $request, $id)
    {
        $product = Product::findOrFail($id);

        if ($product->merchant_id !== $request->user()->merchant->id) {
            return $this->errorResponse('Unauthorized', 403);
        }

        $validator = Validator::make($request->all(), [
            'secondary_category_id' => 'sometimes|exists:secondary_categories,id',
            'name' => 'sometimes|string|max:255',
            'brand' => 'sometimes|string|max:255',
            'unit' => 'sometimes|string|max:100',
            'description' => 'nullable|string',
            'images' => 'nullable|array',
            'price' => 'sometimes|numeric|min:0',
            'compare_price' => 'nullable|numeric|min:0',
            'stock_count' => 'sometimes|integer|min:0',
            'is_available' => 'boolean',
            'is_featured' => 'boolean',
            'attributes' => 'nullable|array',
        ]);

        if ($validator->fails()) {
            return $this->errorResponse('Validation failed', 422, $validator->errors()->toArray());
        }

        $product->update($request->only([
            'secondary_category_id', 'name', 'brand', 'unit', 'description', 'images', 'price',
            'compare_price', 'stock_count', 'is_available', 'is_featured', 'attributes'
        ]));

        // Clear caches for this product
        $this->globalCacheFlush();

        return $this->successResponse($product, 'Product updated successfully');
    }

    public function destroy(Request $request, $id)
    {
        $product = Product::findOrFail($id);

        if ($product->merchant_id !== $request->user()->merchant->id) {
            return $this->errorResponse('Unauthorized', 403);
        }

        $product->delete();

        // Clear caches
        $this->globalCacheFlush();

        return $this->successResponse(null, 'Product deleted successfully');
    }

    public function merchantProducts(Request $request)
    {
        $merchant = $request->user()->merchant;
        $cacheKey = "merchant_products:{$merchant->id}:" . md5($request->fullUrl());

        $products = $this->remember($cacheKey, function () use ($request, $merchant) {
            $query = Product::where('merchant_id', $merchant->id)
                ->with(['secondaryCategory.primaryCategory', 'masterProduct'])
                ->orderBy('created_at', 'desc');

            return $this->paginateQuery($query, $request, 20, 100);
        }, 30);

        return $this->paginatedResponse($products, 'Merchant products retrieved successfully');
    }

    public function scan(Request $request)
    {
        $request->validate([
            'barcode' => 'required|string|max:50',
        ]);

        $barcode = $request->barcode;

        // 1. Check local cache (MasterProduct database)
        $master = \App\Models\MasterProduct::with('secondaryCategory')->where('barcode', $barcode)->first();

        if ($master) {
            return $this->successResponse([
                'master_product_id' => $master->id,
                'name' => $master->name,
                'brand' => $master->brand,
                'secondary_category_id' => $master->secondary_category_id,
                'secondary_category_name' => $master->secondaryCategory?->name,
                'image_url' => $master->primary_image_url,
                'is_cached' => true,
            ], 'Product found in master database');
        }

        // 2. Not in database, trigger enrichment pipeline
        try {
            $enriched = $this->enrichment->enrich('', $barcode);

            if ($enriched['name'] || $enriched['image_url']) {
                $newMaster = \App\Models\MasterProduct::create([
                    'name' => $enriched['name'] ?? 'Unknown Product',
                    'brand' => $enriched['brand'],
                    'barcode' => $barcode,
                    'primary_image_url' => $enriched['image_url'] ?? '',
                    'slug' => \Illuminate\Support\Str::slug(($enriched['name'] ?? 'product') . '-' . $barcode . '-' . uniqid()),
                ]);

                return $this->successResponse([
                    'master_product_id' => $newMaster->id,
                    'name' => $newMaster->name,
                    'brand' => $newMaster->brand,
                    'image_url' => $newMaster->primary_image_url,
                    'is_cached' => false,
                ], 'Product discovered and enriched');
            }
        } catch (\Exception $e) {
            \Log::error('Barcode Scan Enrichment Error: ' . $e->getMessage());
        }

        return $this->errorResponse('Product not found. Please enter details manually.', 404);
    }
}
