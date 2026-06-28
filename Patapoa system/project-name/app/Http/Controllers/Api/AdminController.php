<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Merchant;
use App\Models\Order;
use App\Models\Rider;
use App\Models\Transaction;
use Illuminate\Http\Request;

class AdminController extends Controller
{
    public function dashboard(Request $request)
    {
        $totalOrders = Order::count();
        $totalRevenue = Transaction::where('type', 'payment')
            ->where('status', 'completed')
            ->sum('amount');

        $totalMerchants = Merchant::count();
        $totalRiders = Rider::count();
        $activeRiders = Rider::where('is_online', true)->count();

        $pendingMerchantVerifications = Merchant::where('is_verified', false)->count();
        $pendingRiderVerifications = Rider::where('is_verified', false)->count();

        return $this->successResponse([
            'total_orders' => $totalOrders,
            'total_revenue' => $totalRevenue,
            'total_merchants' => $totalMerchants,
            'total_riders' => $totalRiders,
            'active_riders' => $activeRiders,
            'pending_merchant_verifications' => $pendingMerchantVerifications,
            'pending_rider_verifications' => $pendingRiderVerifications,
        ], 'Dashboard data retrieved successfully');
    }

    public function orders(Request $request)
    {
        $query = Order::with(['customer', 'rider.user', 'orderItems']);

        if ($request->has('status')) {
            $query->where('status', $request->status);
        }

        if ($request->has('date_from')) {
            $query->whereDate('created_at', '>=', $request->date_from);
        }

        if ($request->has('date_to')) {
            $query->whereDate('created_at', '<=', $request->date_to);
        }

        $orders = $this->paginateQuery($query, $request, 50, 200);

        return $this->paginatedResponse($orders, 'Orders retrieved successfully');
    }

    public function merchants(Request $request)
    {
        $query = Merchant::with('user');

        if ($request->has('is_verified')) {
            $query->where('is_verified', $request->is_verified);
        }

        if ($request->has('city')) {
            $query->where('city', 'like', '%' . $request->city . '%');
        }

        $merchants = $this->paginateQuery($query, $request, 50, 200);

        return $this->paginatedResponse($merchants, 'Merchants retrieved successfully');
    }

    public function riders(Request $request)
    {
        $query = Rider::with('user');

        if ($request->has('is_verified')) {
            $query->where('is_verified', $request->is_verified);
        }

        if ($request->has('is_online')) {
            $query->where('is_online', $request->is_online);
        }

        if ($request->has('city')) {
            $query->where('city', $request->city);
        }

        $riders = $this->paginateQuery($query, $request, 50, 200);

        return $this->paginatedResponse($riders, 'Riders retrieved successfully');
    }

    public function transactions(Request $request)
    {
        $query = Transaction::with(['user', 'order']);

        if ($request->has('type')) {
            $query->where('type', $request->type);
        }

        if ($request->has('status')) {
            $query->where('status', $request->status);
        }

        if ($request->has('date_from')) {
            $query->whereDate('created_at', '>=', $request->date_from);
        }

        if ($request->has('date_to')) {
            $query->whereDate('created_at', '<=', $request->date_to);
        }

        $transactions = $this->paginateQuery($query, $request, 50, 200);

        return $this->paginatedResponse($transactions, 'Transactions retrieved successfully');
    }

    public function verifyMerchant(Request $request, $id)
    {
        $merchant = Merchant::findOrFail($id);
        $merchant->update(['is_verified' => true]);

        // TODO: Send notification to merchant

        return $this->successResponse(null, 'Merchant verified successfully');
    }

    public function verifyRider(Request $request, $id)
    {
        $rider = Rider::findOrFail($id);
        $rider->update(['is_verified' => true]);

        // TODO: Send notification to rider

        return $this->successResponse(null, 'Rider verified successfully');
    }
}
