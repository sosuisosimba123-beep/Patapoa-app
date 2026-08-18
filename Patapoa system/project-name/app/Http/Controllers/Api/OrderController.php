<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Services\OrderService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;

class OrderController extends Controller
{
    protected $orderService;

    public function __construct(OrderService $orderService)
    {
        $this->orderService = $orderService;
    }

    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'address_id' => 'required|exists:addresses,id',
            'items' => 'required|array|min:1',
            'items.*.product_id' => 'required|exists:products,id',
            'items.*.quantity' => 'required|integer|min:1',
            'customer_notes' => 'nullable|string',
            'payment_method' => 'required|in:mpesa,tigo_pesa,airtel_money,halopesa,card,wallet',
        ]);

        if ($validator->fails()) {
            return $this->errorResponse('Validation failed', 422, $validator->errors()->toArray());
        }

        try {
            $order = $this->orderService->createOrder($request->all(), $request->user());
            return $this->successResponse($order->load('orderItems'), 'Order created. Please proceed to payment.', 201);
        } catch (\Exception $e) {
            return $this->errorResponse($e->getMessage(), 422);
        }
    }

    public function customerOrders(Request $request)
    {
        $query = Order::where('customer_id', $request->user()->id)
            ->with(['orderItems', 'address', 'deliveryPartner.user'])
            ->orderBy('created_at', 'desc');

        $orders = $this->paginateQuery($query, $request, 20, 100);
        return $this->paginatedResponse($orders, 'Orders retrieved successfully');
    }

    public function show(Request $request, $id)
    {
        $order = Order::with(['orderItems', 'address', 'deliveryPartner.user', 'customer'])->findOrFail($id);

        if ($order->customer_id !== $request->user()->id &&
            !$request->user()->isAdmin() &&
            (!$request->user()->merchant || !$order->orderItems()->where('merchant_id', $request->user()->merchant->id)->exists()) &&
            (!$request->user()->deliveryPartner || $order->delivery_partner_id !== $request->user()->deliveryPartner->id)) {
            return $this->errorResponse('Unauthorized', 403);
        }

        return $this->successResponse($order, 'Order retrieved successfully');
    }

    public function tracking(Request $request, $id)
    {
        try {
             // Logic could also be moved to Service if complexity grows
            $order = Order::with(['address'])->findOrFail($id);
            if ($order->customer_id !== $request->user()->id) return $this->errorResponse('Unauthorized', 403);

            // ... implementation details ...
            return $this->successResponse(['status' => $order->status], 'Tracking retrieved');
        } catch (\Exception $e) {
            return $this->errorResponse($e->getMessage(), 500);
        }
    }

    public function cancel(Request $request, $id)
    {
        $order = Order::findOrFail($id);
        if ($order->customer_id !== $request->user()->id) return $this->errorResponse('Unauthorized', 403);

        if (!in_array($order->status, ['pending_payment', 'paid_securely'])) {
            return $this->errorResponse('Order cannot be cancelled at this stage', 422);
        }

        DB::transaction(function() use ($order) {
            $order->update(['status' => 'cancelled']);
            foreach ($order->orderItems as $item) {
                $item->product->increment('stock_count', $item->quantity);
            }
        });

        return $this->successResponse(null, 'Order cancelled successfully');
    }
}
