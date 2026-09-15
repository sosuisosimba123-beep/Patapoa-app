<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Services\WalletService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use App\Services\PushNotificationService;

class DeliveryPartnerController extends Controller
{
    protected $notifications;
    protected $walletService;

    public function __construct(PushNotificationService $notifications, WalletService $walletService)
    {
        $this->notifications = $notifications;
        $this->walletService = $walletService;
    }

    /**
     * Helper to get partner or create if missing
     */
    private function getPartnerOrHeal(Request $request)
    {
        $user = $request->user();
        $partner = $user->deliveryPartner;

        if (!$partner && $user->user_type === 'rider') {
            $partner = $user->deliveryPartner()->create([
                'vehicle_type' => 'motorcycle',
                'city' => 'Dar es Salaam',
                'is_online' => false,
                'is_verified' => true,
            ]);
            // Refresh to ensure we have the ID
            $user->load('deliveryPartner');
            $partner = $user->deliveryPartner;
        }

        return $partner;
    }

    public function updateOrderStatus(Request $request, $id)
    {
        $order = Order::findOrFail($id);
        $partner = $this->getPartnerOrHeal($request);

        if (!$partner || $order->delivery_partner_id !== $partner->id) return $this->errorResponse('Unauthorized', 403);

        // ... rest of the method ...
    }

    public function earnings(Request $request)
    {
        $wallet = $request->user()->wallet;
        return $this->successResponse([
            'available_balance' => $wallet ? $wallet->balance : 0,
            'pending_balance' => $wallet ? $wallet->pending_balance : 0,
        ], 'Earnings retrieved');
    }

    public function profile(Request $request)
    {
        $user = $request->user();
        $partner = $this->getPartnerOrHeal($request);

        if (!$partner) return $this->errorResponse('Delivery Partner profile not found', 404);

        return $this->successResponse([
            'id' => $partner->id,
            'name' => $user->name,
            'phone' => $user->phone,
            'email' => $user->email,
            'vehicle_type' => $partner->vehicle_type,
            'city' => $partner->city,
            'rating' => $partner->rating,
            'total_deliveries' => $partner->total_deliveries,
            'is_online' => $partner->is_online,
        ], 'Profile retrieved');
    }

    public function updateProfile(Request $request)
    {
        $user = $request->user();
        $partner = $this->getPartnerOrHeal($request);

        $validator = Validator::make($request->all(), [
            'name' => 'sometimes|string|max:255',
            'email' => 'sometimes|email|unique:users,email,' . $user->id,
            'vehicle_type' => 'sometimes|string|in:bicycle,motorcycle,car',
        ]);

        if ($validator->fails()) return $this->errorResponse('Validation failed', 422, $validator->errors()->toArray());

        $user->update($request->only(['name', 'email']));
        if ($partner) $partner->update($request->only(['vehicle_type']));

        return $this->successResponse($this->profile($request)->original['data'], 'Profile updated');
    }

    public function goOnline(Request $request)
    {
        $partner = $this->getPartnerOrHeal($request);
        if (!$partner) return $this->errorResponse('Profile not found', 404);

        $partner->update(['is_online' => true]);
        return $this->successResponse(['is_online' => true], 'Partner is now online');
    }

    public function goOffline(Request $request)
    {
        $partner = $this->getPartnerOrHeal($request);
        if (!$partner) return $this->errorResponse('Profile not found', 404);

        $partner->update(['is_online' => false]);
        return $this->successResponse(['is_online' => false], 'Partner is now offline');
    }

    public function updateLocation(Request $request)
    {
        $partner = $this->getPartnerOrHeal($request);
        if (!$partner) return $this->errorResponse('Profile not found', 404);

        $validator = Validator::make($request->all(), [
            'latitude' => 'required|numeric',
            'longitude' => 'required|numeric',
        ]);

        if ($validator->fails()) return $this->errorResponse('Invalid coordinates', 422);

        $partner->update([
            'current_latitude' => $request->latitude,
            'current_longitude' => $request->longitude,
            'last_located_at' => now(),
        ]);

        return $this->successResponse(null, 'Location updated');
    }

    public function availableOrders(Request $request)
    {
        $partner = $this->getPartnerOrHeal($request);
        if (!$partner || !$partner->is_online) return $this->successResponse([], 'Go online to see orders');

        $orders = Order::where('status', 'ready_for_pickup')
            ->whereNull('delivery_partner_id')
            ->with(['orderItems.product', 'customer', 'address'])
            ->get();

        return $this->successResponse($orders, 'Available orders retrieved');
    }

    public function partnerOrders(Request $request)
    {
        $partner = $this->getPartnerOrHeal($request);
        if (!$partner) return $this->errorResponse('Rider profile missing', 404);

        $orders = Order::where('delivery_partner_id', $partner->id)
            ->with(['customer', 'address'])
            ->orderBy('created_at', 'desc')
            ->get();

        return $this->successResponse($orders, 'Trip history retrieved');
    }
}
