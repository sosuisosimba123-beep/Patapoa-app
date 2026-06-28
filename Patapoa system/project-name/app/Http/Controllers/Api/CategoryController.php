<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Category;
use Illuminate\Http\Request;

class CategoryController extends Controller
{
    public function index(Request $request)
    {
        $query = Category::where('is_active', true)
            ->orderBy('sort_order');

        // Categories are usually small, but support pagination if needed
        if ($request->has('page') || $request->has('limit')) {
            $categories = $this->paginateQuery($query, $request, 50, 200);
            return $this->paginatedResponse($categories, 'Categories retrieved successfully');
        }

        $categories = $query->get();
        return $this->successResponse($categories, 'Categories retrieved successfully');
    }

    public function show($id)
    {
        $category = Category::with('products')->findOrFail($id);
        return $this->successResponse($category, 'Category retrieved successfully');
    }
}
