<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;

class UploadController extends Controller
{
    public function uploadImage(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'image' => 'required|image|mimes:jpeg,png,jpg,gif,webp|max:5120',
            'folder' => 'nullable|string|in:products,avatars,merchants,riders',
        ]);

        if ($validator->fails()) {
            return $this->errorResponse('Validation failed', 422, $validator->errors()->toArray());
        }

        $folder = $request->input('folder', 'products');
        $file = $request->file('image');
        
        $fileName = Str::uuid() . '_' . time() . '.' . $file->getClientOriginalExtension();
        $path = $file->storeAs("uploads/{$folder}", $fileName, 'public');

        return $this->successResponse([
            'url' => asset('storage/' . $path),
            'path' => $path,
        ], 'Image uploaded successfully');
    }

    public function uploadMultipleImages(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'images' => 'required|array',
            'images.*' => 'image|mimes:jpeg,png,jpg,gif,webp|max:5120',
            'folder' => 'nullable|string|in:products,avatars,merchants,riders',
        ]);

        if ($validator->fails()) {
            return $this->errorResponse('Validation failed', 422, $validator->errors()->toArray());
        }

        $folder = $request->input('folder', 'products');
        $urls = [];

        foreach ($request->file('images') as $file) {
            $fileName = Str::uuid() . '_' . time() . '.' . $file->getClientOriginalExtension();
            $path = $file->storeAs("uploads/{$folder}", $fileName, 'public');
            $urls[] = asset('storage/' . $path);
        }

        return $this->successResponse([
            'urls' => $urls,
        ], 'Images uploaded successfully');
    }
}
