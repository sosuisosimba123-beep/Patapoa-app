<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Merchant;
use App\Models\Order;
use App\Models\DeliveryPartner;
use App\Models\Transaction;
use App\Models\User;
use App\Models\Waitlist;
use App\Models\SearchLog;
use App\Models\DeliveryPricingRule;
use App\Models\PlatformSetting;
use App\Models\Product;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;

class AdminController extends Controller
{
    public function dashboard()
    {
        $paidOrdersQuery = Order::whereIn('payment_status', ['paid', 'completed']);

        $stats = [
            'total_revenue' => Transaction::where('type', 'payment')->where('status', 'completed')->sum('amount'),
            'active_riders' => DeliveryPartner::where('is_online', true)->count(),
            'new_merchants' => Merchant::whereDate('created_at', now())->count(),
            'pending_payouts' => Transaction::where('type', 'payout')->where('status', 'pending')->sum('amount'),
            'total_orders' => Order::count(),
            'daily_gmv' => Order::whereDate('created_at', today())->whereIn('payment_status', ['paid', 'completed'])->sum('total'),
            'platform_earnings' => $paidOrdersQuery->sum('platform_fee'),
            'total_users' => User::count(),
            'total_products' => Product::count(),
        ];

        $recentActivity = Transaction::with(['user', 'order'])
            ->latest()
            ->take(5)
            ->get();

        $topMerchants = Merchant::withCount('orders')
            ->get()
            ->map(function ($merchant) {
                /** @var Merchant $merchant */
                $merchant->revenue = $merchant->orders()->sum('subtotal');
                return $merchant;
            })
            ->sortByDesc('revenue')
            ->take(3);

        // Expansion & System Data
        $unmetDemand = collect();
        $waitlistHotspots = collect();
        $systemData = [
            'customers_count' => User::where('user_type', 'customer')->count(),
            'merchants_count' => Merchant::count(),
            'riders_count' => DeliveryPartner::count(),
            'suspended_merchants_count' => User::where('user_type', 'merchant')->where('is_active', false)->count(),
            'active_orders_count' => Order::whereIn('status', ['placed', 'confirmed', 'processing', 'picked_up', 'out_for_delivery'])->count(),
        ];

        try {
            $unmetDemand = SearchLog::select('query', DB::raw('count(*) as search_count'))
                ->where('has_results', false)
                ->groupBy('query')
                ->orderBy('search_count', 'desc')
                ->limit(5)
                ->get();

            $waitlistHotspots = Waitlist::select('city', DB::raw('count(*) as count'))
                ->groupBy('city')
                ->orderBy('count', 'desc')
                ->get();
        } catch (\Exception $e) {
            Log::warning('Admin Dashboard: Expansion tables missing.');
        }

        return view('admin.dashboard', compact('stats', 'recentActivity', 'topMerchants', 'unmetDemand', 'waitlistHotspots', 'systemData'));
    }

    public function orders()
    {
        $orders = Order::with(['customer'])
            ->latest()
            ->paginate(20);

        return view('admin.orders', compact('orders'));
    }

    public function merchants()
    {
        $merchants = Merchant::with(['user'])
            ->withCount('orders')
            ->latest()
            ->paginate(15);

        $suspendedCount = User::where('user_type', 'merchant')->where('is_active', false)->count();

        return view('admin.merchants', compact('merchants', 'suspendedCount'));
    }

    public function verifyMerchant($id)
    {
        $merchant = Merchant::findOrFail($id);
        $merchant->update(['is_verified' => true, 'is_online' => true]);

        return back()->with('success', 'Merchant verified successfully');
    }

    public function verifyRider($id)
    {
        $rider = DeliveryPartner::findOrFail($id);
        $rider->update(['is_verified' => true]);

        return back()->with('success', 'Delivery partner verified successfully');
    }

    public function deliveries()
    {
        $riders = DeliveryPartner::with(['user'])
            ->withCount('orders')
            ->latest()
            ->paginate(15);

        $activeDeliveries = Order::with(['deliveryPartner.user', 'customer', 'merchant'])
            ->whereIn('status', ['confirmed', 'processing', 'picked_up', 'out_for_delivery'])
            ->orderBy('updated_at', 'desc')
            ->get();

        $avgRating = DeliveryPartner::avg('rating') ?? 0;
        $totalDebt = 0; // Placeholder for future implementation

        return view('admin.deliveries', compact('riders', 'activeDeliveries', 'avgRating', 'totalDebt'));
    }

    public function storeRider(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'phone' => 'required|string|unique:users,phone',
            'password' => 'required|string|min:6',
            'city' => 'required|string',
        ]);

        try {
            DB::transaction(function () use ($request) {
                $user = User::create([
                    'name' => $request->input('name'),
                    'phone' => $request->input('phone'),
                    'email' => $request->input('phone') . '@patapoa.com',
                    'password' => Hash::make($request->input('password')),
                    'user_type' => 'rider',
                    'is_active' => true,
                    'is_verified' => true,
                    'phone_verified_at' => now(),
                ]);

                $user->wallet()->create([
                    'wallet_type' => 'rider',
                    'balance' => 0,
                    'currency' => 'TZS',
                ]);

                $user->deliveryPartner()->create([
                    'vehicle_type' => $request->input('vehicle_type', 'motorcycle'),
                    'city' => $request->input('city'),
                    'is_online' => false,
                    'is_verified' => true,
                ]);
            });
            return back()->with('success', 'Delivery partner added successfully');
        } catch (\Exception $e) {
            return back()->with('error', 'Error: ' . $e->getMessage());
        }
    }

    public function storeMerchant(Request $request)
    {
        $request->validate([
            'store_name' => 'required|string|max:255',
            'owner_name' => 'required|string|max:255',
            'phone' => 'required|string|unique:users,phone',
            'password' => 'required|string|min:6',
            'city' => 'required|string',
        ]);

        try {
            DB::transaction(function () use ($request) {
                $user = User::create([
                    'name' => $request->input('owner_name'),
                    'phone' => $request->input('phone'),
                    'email' => $request->input('phone') . '@patapoa.com',
                    'password' => Hash::make($request->input('password')),
                    'user_type' => 'merchant',
                    'is_active' => true,
                    'is_verified' => true,
                    'phone_verified_at' => now(),
                ]);

                $user->wallet()->create([
                    'wallet_type' => 'merchant',
                    'balance' => 0,
                    'currency' => 'TZS',
                ]);

                $user->merchant()->create([
                    'store_name' => $request->input('store_name'),
                    'address' => 'Pending Setup',
                    'city' => $request->input('city'),
                    'is_verified' => true,
                    'is_online' => true,
                ]);
            });
            return back()->with('success', 'Supermarket partner added successfully');
        } catch (\Exception $e) {
            return back()->with('error', 'Error: ' . $e->getMessage());
        }
    }

    public function toggleUserStatus($id)
    {
        $user = User::findOrFail($id);
        $user->update(['is_active' => !$user->is_active]);

        return back()->with('success', 'User status updated');
    }

    public function settings()
    {
        try {
            $pricingRules = DeliveryPricingRule::all();
            $platformSettings = PlatformSetting::all()->pluck('value', 'key');
        } catch (\Exception $e) {
            $pricingRules = collect();
            $platformSettings = collect();
            Log::warning('Admin Settings: Tables missing. Please run php artisan migrate.');
        }
        return view('admin.settings', compact('pricingRules', 'platformSettings'));
    }

    public function updatePlatformSettings(Request $request)
    {
        $settings = $request->only([
            'merchant_commission_rate',
            'rider_commission_rate',
            'convenience_fee'
        ]);

        foreach ($settings as $key => $value) {
            // Convert percentage back to decimal if applicable
            if (str_contains($key, 'rate')) {
                $value = (float) $value / 100;
            }
            PlatformSetting::where('key', $key)->update(['value' => $value]);
        }

        return back()->with('success', 'Platform financial settings updated');
    }

    public function updatePricing(Request $request)
    {
        $request->validate([
            'zone_name' => 'required|string',
            'base_fee' => 'required|numeric',
            'per_km_fee' => 'required|numeric',
            'max_distance' => 'required|numeric',
            'surge_multiplier' => 'required|numeric|min:1',
        ]);

        DeliveryPricingRule::updateOrCreate(
            ['zone_name' => $request->input('zone_name')],
            $request->only(['base_fee', 'per_km_fee', 'max_distance', 'surge_multiplier', 'min_basket_value_for_free_delivery'])
        );

        return back()->with('success', 'Pricing updated');
    }

    public function transactions(Request $request)
    {
        $query = Transaction::with(['user', 'order'])->latest();

        // Global Summaries (calculated before pagination)
        $summary = [
            'total_sales' => Transaction::where('type', 'payment')->where('status', 'completed')->sum('amount'),
            'platform_revenue' => Order::whereIn('payment_status', ['paid', 'completed'])->sum('platform_fee'),
            'pending_payouts' => Transaction::where('type', 'payout')->where('status', 'pending')->sum('amount'),
            'completed_payouts' => Transaction::where('type', 'payout')->where('status', 'completed')->sum('amount'),
        ];

        if ($request->has('type') && $request->type != 'all') {
            $query->where('type', $request->type);
        }

        if ($request->has('user_id')) {
            $query->where('user_id', $request->user_id);
        }

        if ($request->has('status') && $request->status != 'all') {
            $query->where('status', $request->status);
        }

        if ($request->has('export')) {
            return $this->exportTransactionsCsv($query->get());
        }

        $transactions = $query->paginate(25);

        return view('admin.transactions', compact('transactions', 'summary'));
    }

    protected function exportTransactionsCsv($transactions)
    {
        $fileName = 'transactions_' . date('Y-m-d') . '.csv';
        $headers = [
            "Content-type"        => "text/csv",
            "Content-Disposition" => "attachment; filename=$fileName",
            "Pragma"              => "no-cache",
            "Cache-Control"       => "must-revalidate, post-check=0, pre-check=0",
            "Expires"             => "0"
        ];

        $columns = ['ID', 'Type', 'User', 'Amount', 'Currency', 'Status', 'Date'];

        $callback = function() use($transactions, $columns) {
            $file = fopen('php://output', 'w');
            fputcsv($file, $columns);

            foreach ($transactions as $t) {
                fputcsv($file, [
                    $t->id,
                    $t->type,
                    $t->user->name ?? 'System',
                    $t->amount,
                    $t->currency,
                    $t->status,
                    $t->created_at
                ]);
            }

            fclose($file);
        };

        return response()->stream($callback, 200, $headers);
    }

    /**
     * Development Utility: Manually mark an order as paid
     */
    public function markAsPaid(Request $request, $orderId)
    {
        $order = Order::findOrFail($orderId);

        if ($order->payment_status === 'paid') {
            return back()->with('error', 'Order is already marked as paid');
        }

        DB::transaction(function() use ($order) {
            $order->update([
                'payment_status' => 'paid',
                'status' => 'confirmed',
                'confirmed_at' => now(),
            ]);

            // Create a dummy successful transaction if none exists
            Transaction::updateOrCreate(
                ['order_id' => $order->id, 'type' => 'payment'],
                [
                    'user_id' => $order->customer_id,
                    'status' => 'completed',
                    'amount' => $order->total,
                    'currency' => 'TZS',
                    'payment_method' => $order->payment_method ?? 'mpesa',
                    'description' => 'Manual Confirmation (Dev Utility)',
                    'processed_at' => now(),
                ]
            );
        });

        return back()->with('success', 'Order #' . $order->display_id . ' marked as paid successfully.');
    }
}
