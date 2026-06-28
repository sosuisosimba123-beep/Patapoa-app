  <?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Product;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class ProductController extends Controller
{
    public function index(Request $request)
    {
        $cacheKey = 'products:' . md5($request->fullUrl());

        $products = $this->remember($cacheKey, function () use ($request) {
            $query = Product::with(['merchant:id,name,logo,address', 'category:id,name'])
                ->where('is_available', true);

            // Filter by category
            if ($request->has('category_id')) {
                $query->where('category_id', $request->category_id);
            }

            // Search by name
            if ($request->has('q')) {
                $query->where('name', 'like', '%' . $request->q . '%');
            }

            // Filter by merchant
            if ($request->has('merchant_id')) {
                $query->where('merchant_id', $request->merchant_id);
            }

            // Featured products
            if ($request->has('featured') && $request->featured) {
                $query->where('is_featured', true);
            }

            // Sort
            $sort = $request->get('sort', 'created_at');
            $direction = $request->get('direction', 'desc');
            $query->orderBy($sort, $direction);

            return $this->paginateQuery($query, $request, 20, 100);
        }, 30); // 30-second cache for product listings

        return $this->paginatedResponse($products, 'Products retrieved successfully');
    }

    public function show(Request $request, $id)
    {
        $cacheKey = "product:{$id}";

        $product = $this->remember($cacheKey, function () use ($request, $id) {
            $query = Product::with(['merchant:id,name,logo,address,phone,rating', 'category:id,name']);
            
            // Selective field loading for list views
            if ($request->has('fields')) {
                $fields = array_map('trim', explode(',', $request->get('fields')));
                $query->select(array_merge(['id', 'merchant_id', 'category_id'], $fields));
            }
            
            return $query->findOrFail($id);
        }, 60); // 60-second cache for individual product

        return $this->successResponse($product, 'Product retrieved successfully');
    }

    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'category_id' => 'required|exists:categories,id',
            'name' => 'required|string|max:255',
            'description' => 'nullable|string',
            'images' => 'nullable|array',
            'price' => 'required|numeric|min:0',
            'compare_price' => 'nullable|numeric|min:0',
            'stock_count' => 'required|integer|min:0',
            'is_available' => 'boolean',
            'is_featured' => 'boolean',
            'attributes' => 'nullable|array',
        ]);

        if ($validator->fails()) {
            return $this->errorResponse('Validation failed', 422, $validator->errors()->toArray());
        }

        $merchant = $request->user()->merchant;
        
        $product = Product::create([
            'merchant_id' => $merchant->id,
            'category_id' => $request->category_id,
            'name' => $request->name,
            'description' => $request->description,
            'images' => $request->images,
            'price' => $request->price,
            'compare_price' => $request->compare_price,
            'stock_count' => $request->stock_count,
            'is_available' => $request->is_available ?? true,
            'is_featured' => $request->is_featured ?? false,
            'attributes' => $request->attributes,
        ]);

        // Clear product listing cache when new product is added
        $this->forget('products:');

        return $this->successResponse($product, 'Product created successfully', 201);
    }

    public function update(Request $request, $id)
    {
        $product = Product::findOrFail($id);
        
        if ($product->merchant_id !== $request->user()->merchant->id) {
            return $this->errorResponse('Unauthorized', 403);
        }

        $validator = Validator::make($request->all(), [
            'category_id' => 'sometimes|exists:categories,id',
            'name' => 'sometimes|string|max:255',
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
            'category_id', 'name', 'description', 'images', 'price',
            'compare_price', 'stock_count', 'is_available', 'is_featured', 'attributes'
        ]));

        // Clear caches for this product
        $this->forget("product:{$id}");
        $this->forget('products:');

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
        $this->forget("product:{$id}");
        $this->forget('products:');

        return $this->successResponse(null, 'Product deleted successfully');
    }

    public function merchantProducts(Request $request)
    {
        $merchant = $request->user()->merchant;
        $cacheKey = "merchant_products:{$merchant->id}:" . md5($request->fullUrl());
        
        $products = $this->remember($cacheKey, function () use ($request, $merchant) {
            $query = Product::where('merchant_id', $merchant->id)
                ->with('category:id,name')
                ->orderBy('created_at', 'desc');
            
            return $this->paginateQuery($query, $request, 20, 100);
        }, 30);

        return $this->paginatedResponse($products, 'Merchant products retrieved successfully');
    }
}
