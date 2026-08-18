<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\PrimaryCategory;
use Illuminate\Http\Request;

class PrimaryCategoryController extends Controller
{
    /**
     * Display a listing of primary categories with their secondary categories.
     */
    public function index(Request $request)
    {
        $categories = PrimaryCategory::with('secondaryCategories')
            ->where('is_active', true)
            ->orderBy('sort_order')
            ->get();

        return $this->successResponse($categories, 'Categories retrieved successfully');
    }

    /**
     * Display the specified primary category.
     */
    public function show(string $slug)
    {
        $category = PrimaryCategory::with('secondaryCategories')
            ->where('slug', $slug)
            ->firstOrFail();

        return $this->successResponse($category, 'Category details retrieved');
    }
}
