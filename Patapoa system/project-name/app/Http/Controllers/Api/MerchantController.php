<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\Merchant;
use App\Services\MerchantService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use App\Services\PushNotificationService;

class MerchantController extends Controller
{
    protected $notifications;
    protected $merchantService;

    public function __construct(PushNotificationService $notifications, MerchantService $merchantService)
    {
        $this->notifications = $notifications;
        $this->merchantService = $merchantService;
    }

    public function dashboard(Request $request)
    {
        $stats = $this->merchantService->getDashboardStats($request->user()->merchant);
        return $this->successResponse($stats, 'Dashboard data retrieved successfully');
    }

    public function nearby(Request $request)
    {
        $lat = $request->get('latitude');
        $lng = $request->get('longitude');
        $radius = $request->get('radius', 15);

        $query = Merchant::where('is_verified', true)
            ->where('is_online', true);

        if ($lat && $lng) {
            $query->withinRadius($lat, $lng, $radius)
                ->withDistance($lat, $lng);
        }

        $merchants = $query->orderBy('rating', 'desc')->get();

        return $this->successResponse($merchants, 'Nearby merchants retrieved successfully');
    }

    public function updateProfile(Request $request)
    {
        $user = $request->user();
        $merchant = $user->merchant;

        $validator = Validator::make($request->all(), [
            'name' => 'sometimes|string|max:255',
            'email' => 'sometimes|email|unique:users,email,' . $user->id,
            'phone' => 'sometimes|string|unique:users,phone,' . $user->id,
            'store_name' => 'sometimes|string|max:255',
            'city' => 'sometimes|string|max:255',
        ]);

        if ($validator->fails()) {
            return $this->errorResponse('Validation failed', 422, $validator->errors()->toArray());
        }

        $user->update($request->only(['name', 'email', 'phone']));
        if ($merchant) $merchant->update($request->only(['store_name', 'city']));

        return $this->successResponse($user->load('merchant'), 'Profile updated successfully');
    }

    public function updatePayout(Request $request)
    {
        $merchant = $request->user()->merchant;
        if (!$merchant) return $this->errorResponse('Merchant profile not found', 404);

        $validator = Validator::make($request->all(), [
            'payout_method' => 'required|in:mpesa,tigo_pesa,airtel_money,bank',
            'payout_account' => 'required|string|max:255',
        ]);

        if ($validator->fails()) return $this->errorResponse('Validation failed', 422, $validator->errors()->toArray());

        $merchant->update($request->only(['payout_method', 'payout_account']));
        return $this->successResponse($merchant->fresh(), 'Payout details updated.');
    }

    public function orders(Request $request)
    {
        $merchant = $request->user()->merchant;

        $query = Order::whereHas('orderItems', function ($query) use ($merchant) {
            $query->where('merchant_id', $merchant->id);
        })
        ->whereNotIn('status', ['pending_payment'])
        ->with(['orderItems', 'customer', 'address'])
        ->orderBy('created_at', 'desc');

        $orders = $this->paginateQuery($query, $request, 20, 100);
        return $this->paginatedResponse($orders, 'Merchant orders retrieved successfully');
    }

    public function updateOrderStatus(Request $request, $id)
    {
        $order = Order::findOrFail($id);
        $merchant = $request->user()->merchant;

        if (!$merchant->is_verified) return $this->errorResponse('Account not verified.', 403);
        if (!$order->orderItems()->where('merchant_id', $merchant->id)->exists()) return $this->errorResponse('Unauthorized', 403);

        $validator = Validator::make($request->all(), ['status' => 'required|in:confirmed,preparing,ready_for_pickup']);
        if ($validator->fails()) return $this->errorResponse('Validation failed', 422, $validator->errors()->toArray());

        $status = $request->input('status');
        $validTransitions = [
            'paid_securely' => ['confirmed'],
            'confirmed' => ['preparing'],
            'preparing' => ['ready_for_pickup'],
        ];

        if (!isset($validTransitions[$order->status]) || !in_array($status, $validTransitions[$order->status])) {
            return $this->errorResponse('Invalid status transition', 422);
        }

        $order->update(['status' => $status]);

        if ($status === 'confirmed') {
            $order->update(['confirmed_at' => now()]);
            $this->notifications->sendToUser($order->customer, 'Order Accepted', "Order #{$order->id} is being prepared.");
        } else if ($status === 'ready_for_pickup') {
            $this->notifications->sendToUser($order->customer, 'Order Ready', "Order #{$order->id} is ready for pickup!");

            // Notify Riders
            $this->notifications->sendToTopic('riders', 'Order Ready', "A nearby order #{$order->id} is ready for pickup.");
        }

        return $this->successResponse($order->fresh(), 'Order status updated');
    }

    public function updateLocation(Request $request)
    {
        $merchant = $request->user()->merchant;
        if (!$merchant) return $this->errorResponse('Merchant profile not found', 404);

        $validator = Validator::make($request->all(), [
            'latitude' => 'required|numeric|between:-90,90',
            'longitude' => 'required|numeric|between:-180,180',
            'city' => 'sometimes|string|max:100',
        ]);

        if ($validator->fails()) return $this->errorResponse('Validation failed', 422, $validator->errors()->toArray());

        $merchant->update($request->only(['latitude', 'longitude', 'city', 'district', 'landmark']));
        return $this->successResponse($merchant->fresh(), 'Store location updated.');
    }
}
