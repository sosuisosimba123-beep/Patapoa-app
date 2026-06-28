<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Address;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class AddressController extends Controller
{
    public function index(Request $request)
    {
        $query = $request->user()->addresses()->orderBy('is_default', 'desc');
        
        $addresses = $this->paginateQuery($query, $request, 20, 100);
        
        return $this->paginatedResponse($addresses, 'Addresses retrieved successfully');
    }

    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'label' => 'required|string|max:100',
            'recipient_name' => 'required|string|max:255',
            'phone' => 'required|string|max:20',
            'address_line_1' => 'required|string',
            'address_line_2' => 'nullable|string',
            'city' => 'required|string|max:100',
            'region' => 'nullable|string|max:100',
            'latitude' => 'nullable|numeric|between:-90,90',
            'longitude' => 'nullable|numeric|between:-180,180',
        ]);

        if ($validator->fails()) {
            return $this->errorResponse('Validation failed', 422, $validator->errors()->toArray());
        }

        $address = $request->user()->addresses()->create($request->all());

        // If this is the first address, make it default
        if ($request->user()->addresses()->count() === 1) {
            $address->update(['is_default' => true]);
        }

        return $this->successResponse($address, 'Address created successfully', 201);
    }

    public function show(Request $request, $id)
    {
        $address = $request->user()->addresses()->findOrFail($id);
        return $this->successResponse($address, 'Address retrieved successfully');
    }

    public function update(Request $request, $id)
    {
        $address = $request->user()->addresses()->findOrFail($id);

        $validator = Validator::make($request->all(), [
            'label' => 'sometimes|string|max:100',
            'recipient_name' => 'sometimes|string|max:255',
            'phone' => 'sometimes|string|max:20',
            'address_line_1' => 'sometimes|string',
            'address_line_2' => 'nullable|string',
            'city' => 'sometimes|string|max:100',
            'region' => 'nullable|string|max:100',
            'latitude' => 'nullable|numeric|between:-90,90',
            'longitude' => 'nullable|numeric|between:-180,180',
        ]);

        if ($validator->fails()) {
            return $this->errorResponse('Validation failed', 422, $validator->errors()->toArray());
        }

        $address->update($request->all());

        return $this->successResponse($address, 'Address updated successfully');
    }

    public function destroy(Request $request, $id)
    {
        $address = $request->user()->addresses()->findOrFail($id);

        if ($address->is_default) {
            return $this->errorResponse('Cannot delete default address', 422);
        }

        $address->delete();

        return $this->successResponse(null, 'Address deleted successfully');
    }

    public function setDefault(Request $request, $id)
    {
        $address = $request->user()->addresses()->findOrFail($id);

        // Remove default from all other addresses
        $request->user()->addresses()->update(['is_default' => false]);

        $address->update(['is_default' => true]);

        return $this->successResponse($address, 'Default address updated');
    }
}
