<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\MasterProduct;
use Illuminate\Http\Request;

class MasterProductController extends Controller
{
    /**
     * Search for master products (for Merchants and Customers)
     */
    public function index(Request $request)
    {
        $query = MasterProduct::with('secondaryCategory.primaryCategory');

        if ($request->has('q')) {
            $q = $request->q;
            $query->where(function($sub) use ($q) {
                $sub->where('name', 'like', "%$q%")
                    ->orWhere('brand', 'like', "%$q%")
                    ->orWhereJsonContains('search_tags', $q);
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

        // Prioritize Generic/Template products so they appear first for merchants
        $query->orderByRaw("CASE WHEN brand = 'Generic' THEN 0 ELSE 1 END");

        $products = $this->paginateQuery($query, $request, 50, 200);

        return $this->paginatedResponse($products, 'Master products retrieved successfully');
    }

    public function show($id)
    {
        $product = MasterProduct::with(['secondaryCategory.primaryCategory', 'listings.merchant'])->findOrFail($id);
        return $this->successResponse($product, 'Master product details retrieved');
    }

    public function showByBarcode($barcode)
    {
        $product = MasterProduct::with('secondaryCategory.primaryCategory')->where('barcode', $barcode)->firstOrFail();
        return $this->successResponse($product, 'Master product found');
    }
}
