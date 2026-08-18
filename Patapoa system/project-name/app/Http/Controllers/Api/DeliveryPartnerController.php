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

    public function updateOrderStatus(Request $request, $id)
    {
        $order = Order::findOrFail($id);
        $partner = $request->user()->deliveryPartner;

        if ($order->delivery_partner_id !== $partner->id) return $this->errorResponse('Unauthorized', 403);

        $validator = Validator::make($request->all(), [
            'status' => 'required|in:rider_heading_to_pickup,at_pickup,picked_up,heading_to_customer,at_dropoff,delivered',
        ]);

        if ($validator->fails()) return $this->errorResponse('Validation failed', 422, $validator->errors()->toArray());

        $status = $request->input('status');
        $order->update(['status' => $status]);

        if ($status === 'delivered') {
            $order->update(['delivered_at' => now(), 'status' => 'completed']);
            $partner->update(['is_on_delivery' => false]);
            $partner->increment('total_deliveries');

            // RELEASE FUNDS: Call WalletService to finalize financial split
            $this->walletService->finalizeEarnings($order);

            $this->notifications->sendToUser($order->customer, 'Order Delivered', "Your order #{$order->id} has been delivered!");
        }

        return $this->successResponse($order->fresh(), 'Order status updated');
    }

    public function earnings(Request $request)
    {
        $wallet = $request->user()->wallet;
        return $this->successResponse([
            'available_balance' => $wallet ? $wallet->balance : 0,
            'pending_balance' => $wallet ? $wallet->pending_balance : 0,
        ], 'Earnings retrieved');
    }
}
