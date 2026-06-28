<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class UserController extends Controller
{
    public function index(Request $request)
    {
        if (!$request->user()->isAdmin()) {
            return $this->errorResponse('Unauthorized', 403);
        }

        $query = User::with(['merchant', 'rider', 'wallet'])
            ->orderBy('created_at', 'desc');

        $users = $this->paginateQuery($query, $request, 50, 200);

        return $this->paginatedResponse($users, 'Users retrieved successfully');
    }

    public function show(Request $request, $id)
    {
        $user = User::findOrFail($id);
        
        if ($request->user()->id !== $user->id && !$request->user()->isAdmin()) {
            return $this->errorResponse('Unauthorized', 403);
        }

        return $this->successResponse(
            $user->load(['merchant', 'rider', 'wallet']),
            'User retrieved successfully'
        );
    }

    public function update(Request $request, $id)
    {
        $user = User::findOrFail($id);
        
        if ($request->user()->id !== $user->id && !$request->user()->isAdmin()) {
            return $this->errorResponse('Unauthorized', 403);
        }

        $validator = Validator::make($request->all(), [
            'name' => 'sometimes|string|max:255',
            'email' => 'sometimes|email|unique:users,email,' . $id,
            'phone' => 'sometimes|string|unique:users,phone,' . $id,
        ]);

        if ($validator->fails()) {
            return $this->errorResponse('Validation failed', 422, $validator->errors()->toArray());
        }

        $user->update($request->only(['name', 'email', 'phone']));

        return $this->successResponse($user, 'User updated successfully');
    }

    public function updateLocation(Request $request, $id)
    {
        $user = User::findOrFail($id);
        
        if ($request->user()->id !== $user->id) {
            return $this->errorResponse('Unauthorized', 403);
        }

        $validator = Validator::make($request->all(), [
            'latitude' => 'required|numeric|between:-90,90',
            'longitude' => 'required|numeric|between:-180,180',
        ]);

        if ($validator->fails()) {
            return $this->errorResponse('Validation failed', 422, $validator->errors()->toArray());
        }

        if ($user->rider) {
            $user->rider->update([
                'current_latitude' => $request->latitude,
                'current_longitude' => $request->longitude,
                'last_location_update' => now(),
            ]);
        }

        return $this->successResponse(null, 'Location updated successfully');
    }

    public function updateFcmToken(Request $request, $id)
    {
        $user = User::findOrFail($id);
        
        if ($request->user()->id !== $user->id) {
            return $this->errorResponse('Unauthorized', 403);
        }

        $validator = Validator::make($request->all(), [
            'fcm_token' => 'required|string',
        ]);

        if ($validator->fails()) {
            return $this->errorResponse('Validation failed', 422, $validator->errors()->toArray());
        }

        $user->update(['fcm_token' => $request->fcm_token]);

        return $this->successResponse(null, 'FCM token updated successfully');
    }
}
