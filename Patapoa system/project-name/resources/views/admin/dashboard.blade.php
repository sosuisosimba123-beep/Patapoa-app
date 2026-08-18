@extends('layouts.admin')

@section('title', 'Overview')

@section('content')
<!-- KPI Cards -->
<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
    <!-- Revenue Card -->
    <div class="bg-white p-4 rounded-xl shadow-sm border border-outline-variant flex flex-col justify-between group hover:border-primary transition-colors">
        <div class="flex justify-between items-start">
            <div class="p-2 bg-primary/10 rounded-lg text-primary">
                <span class="material-symbols-outlined">payments</span>
            </div>
        </div>
        <div class="mt-4">
            <p class="text-xs uppercase tracking-widest text-on-surface-variant font-bold">Total Gross Sales</p>
            <h2 class="text-xl font-black mt-1 text-on-surface">TSH {{ number_format($stats['total_revenue']) }}</h2>
        </div>
    </div>
    <!-- Platform Earnings Card -->
    <div class="bg-white p-4 rounded-xl shadow-sm border border-outline-variant flex flex-col justify-between group hover:border-green-500 transition-colors">
        <div class="flex justify-between items-start">
            <div class="p-2 bg-green-500/10 rounded-lg text-green-600">
                <span class="material-symbols-outlined">account_balance</span>
            </div>
        </div>
        <div class="mt-4">
            <p class="text-xs uppercase tracking-widest text-on-surface-variant font-bold">Platform Earnings (5%)</p>
            <h2 class="text-xl font-black mt-1 text-green-600">TSH {{ number_format($stats['platform_earnings']) }}</h2>
        </div>
    </div>
    <!-- Active Deliveries -->
    <div class="bg-white p-4 rounded-xl shadow-sm border border-outline-variant flex flex-col justify-between group hover:border-primary transition-colors">
        <div class="flex justify-between items-start">
            <div class="p-2 bg-tertiary/10 rounded-lg text-tertiary">
                <span class="material-symbols-outlined">local_shipping</span>
            </div>
            <div class="flex items-center gap-1">
                <span class="relative flex h-2 w-2">
                    <span class="animate-ping absolute inline-flex h-full w-full rounded-full bg-primary opacity-75"></span>
                    <span class="relative inline-flex rounded-full h-2 w-2 bg-primary"></span>
                </span>
                <span class="text-xs font-medium text-on-surface-variant">Live</span>
            </div>
        </div>
        <div class="mt-4">
            <p class="text-xs uppercase tracking-widest text-on-surface-variant font-bold">Active Riders</p>
            <h2 class="text-xl font-black mt-1 text-on-surface">{{ $stats['active_riders'] }} on duty</h2>
        </div>
    </div>
    <!-- Pending Payouts -->
    <div class="bg-white p-4 rounded-xl shadow-sm border border-outline-variant flex flex-col justify-between group hover:border-primary transition-colors">
        <div class="flex justify-between items-start">
            <div class="p-2 bg-error-container/30 rounded-lg text-error">
                <span class="material-symbols-outlined">account_balance_wallet</span>
            </div>
        </div>
        <div class="mt-4">
            <p class="text-xs uppercase tracking-widest text-on-surface-variant font-bold">Total Pending Payouts</p>
            <h2 class="text-xl font-black mt-1 text-on-surface">TSH {{ number_format($stats['pending_payouts']) }}</h2>
        </div>
    </div>
</div>

<!-- Middle Section -->
<div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
    <!-- Platform Growth -->
    <div class="lg:col-span-2 bg-white p-6 rounded-xl shadow-sm border border-outline-variant">
        <div class="flex justify-between items-center mb-6">
            <div>
                <h3 class="text-lg font-bold text-on-surface">Platform Activity</h3>
                <p class="text-sm text-on-surface-variant">Real-time engagement tracking</p>
            </div>
        </div>
        <div class="h-64 w-full relative flex items-end gap-2">
            <div class="flex-1 bg-primary/10 hover:bg-primary transition-all h-[30%] rounded-t-lg"></div>
            <div class="flex-1 bg-primary/10 hover:bg-primary transition-all h-[45%] rounded-t-lg"></div>
            <div class="flex-1 bg-primary/10 hover:bg-primary transition-all h-[40%] rounded-t-lg"></div>
            <div class="flex-1 bg-primary/10 hover:bg-primary transition-all h-[60%] rounded-t-lg"></div>
            <div class="flex-1 bg-primary/10 hover:bg-primary transition-all h-[75%] rounded-t-lg"></div>
            <div class="flex-1 bg-primary/20 hover:bg-primary transition-all h-[85%] rounded-t-lg border-t-4 border-primary"></div>
            <div class="flex-1 bg-primary/10 hover:bg-primary transition-all h-[80%] rounded-t-lg"></div>
            <div class="flex-1 bg-primary/10 hover:bg-primary transition-all h-[95%] rounded-t-lg border-t-4 border-primary"></div>
            <div class="flex-1 bg-primary/10 hover:bg-primary transition-all h-[90%] rounded-t-lg"></div>
        </div>
    </div>

    <!-- Expansion Data / Waitlist -->
    <div class="bg-white p-6 rounded-xl shadow-sm border border-outline-variant">
        <h3 class="text-lg font-bold text-on-surface mb-6">Strategic Expansion Data</h3>

        <div class="mb-6">
            <h4 class="text-xs font-black uppercase tracking-widest text-primary mb-3">Unmet Demand (Top Searches)</h4>
            <div class="space-y-2">
                @foreach($unmetDemand as $item)
                <div class="flex justify-between items-center text-sm p-2 bg-surface-container-low rounded">
                    <span>{{ $item->query }}</span>
                    <span class="font-bold text-primary">{{ $item->search_count }} hits</span>
                </div>
                @endforeach
            </div>
        </div>

        <div>
            <h4 class="text-xs font-black uppercase tracking-widest text-secondary mb-3">Waitlist Hotspots</h4>
            <div class="space-y-2">
                @foreach($waitlistHotspots as $hotspot)
                <div class="flex justify-between items-center text-sm p-2 bg-surface-container-low rounded">
                    <span>{{ $hotspot->city }}</span>
                    <span class="font-bold text-secondary">{{ $hotspot->count }} users</span>
                </div>
                @endforeach
            </div>
        </div>
    </div>
</div>

<!-- Relevant App Data Section -->
<div class="bg-white rounded-xl shadow-sm border border-outline-variant p-6 mt-6">
    <h3 class="text-lg font-bold text-on-surface mb-6 flex items-center gap-2">
        <span class="material-symbols-outlined text-primary">analytics</span>
        Global Platform Overview
    </h3>
    <div class="grid grid-cols-2 md:grid-cols-4 gap-6">
        <div class="space-y-1">
            <p class="text-[10px] uppercase tracking-widest text-on-surface-variant font-black">Registered Customers</p>
            <p class="text-2xl font-black text-on-surface">{{ $systemData['customers_count'] }}</p>
        </div>
        <div class="space-y-1">
            <p class="text-[10px] uppercase tracking-widest text-on-surface-variant font-black">Supermarket Partners</p>
            <p class="text-2xl font-black text-on-surface">{{ $systemData['merchants_count'] }}</p>
        </div>
        <div class="space-y-1">
            <p class="text-[10px] uppercase tracking-widest text-on-surface-variant font-black">Delivery Partners</p>
            <p class="text-2xl font-black text-on-surface">{{ $systemData['riders_count'] }}</p>
        </div>
        <div class="space-y-1">
            <p class="text-[10px] uppercase tracking-widest text-on-surface-variant font-black">Live Order Queue</p>
            <p class="text-2xl font-black text-primary">{{ $systemData['active_orders_count'] }}</p>
        </div>
    </div>

    <div class="mt-8 pt-6 border-t border-outline-variant grid grid-cols-1 md:grid-cols-2 gap-8">
        <div>
            <h4 class="text-xs font-black uppercase tracking-widest text-on-surface-variant mb-4">Inventory Reach</h4>
            <div class="flex items-end gap-3">
                <span class="text-4xl font-black text-on-surface">{{ $stats['total_products'] }}</span>
                <span class="text-sm text-on-surface-variant mb-1">Items listed across all stores</span>
            </div>
        </div>
        <div>
            <h4 class="text-xs font-black uppercase tracking-widest text-on-surface-variant mb-4">Total Order Volume</h4>
            <div class="flex items-end gap-3">
                <span class="text-4xl font-black text-on-surface">{{ $stats['total_orders'] }}</span>
                <span class="text-sm text-on-surface-variant mb-1">Lifetime transactions processed</span>
            </div>
        </div>
    </div>
</div>

<!-- Bottom Section: Recent Activity -->
<div class="bg-white rounded-xl shadow-sm border border-outline-variant overflow-hidden">
    <div class="p-6 border-b border-outline-variant flex justify-between items-center">
        <h3 class="text-lg font-bold text-on-surface">Recent Activity</h3>
        <a href="{{ route('admin.transactions') }}" class="text-primary font-bold text-xs uppercase tracking-widest hover:underline">View All</a>
    </div>
    <div class="overflow-x-auto">
        <table class="w-full text-left">
            <thead>
                <tr class="bg-surface-container-low">
                    <th class="px-6 py-3 text-xs font-bold uppercase tracking-widest text-on-surface-variant">Event</th>
                    <th class="px-6 py-3 text-xs font-bold uppercase tracking-widest text-on-surface-variant">User</th>
                    <th class="px-6 py-3 text-xs font-bold uppercase tracking-widest text-on-surface-variant">Amount</th>
                    <th class="px-6 py-3 text-xs font-bold uppercase tracking-widest text-on-surface-variant">Status</th>
                </tr>
            </thead>
            <tbody class="divide-y divide-outline-variant">
                @foreach($recentActivity as $activity)
                <tr class="hover:bg-surface-container-low transition-colors">
                    <td class="px-6 py-4">
                        <div class="flex items-center gap-3">
                            <span class="material-symbols-outlined text-primary text-lg">{{ $activity->type === 'payment' ? 'package_2' : 'account_balance_wallet' }}</span>
                            <span class="text-sm font-medium">{{ $activity->description }}</span>
                        </div>
                    </td>
                    <td class="px-6 py-4 text-sm">{{ $activity->user->name ?? 'System' }}</td>
                    <td class="px-6 py-4 text-sm font-bold">TSH {{ number_format($activity->amount) }}</td>
                    <td class="px-6 py-4">
                        <span class="px-2 py-1 rounded text-[10px] font-bold uppercase tracking-widest {{ $activity->status === 'completed' ? 'bg-primary/10 text-primary' : 'bg-error-container text-error' }}">
                            {{ $activity->status }}
                        </span>
                    </td>
                </tr>
                @endforeach
            </tbody>
        </table>
    </div>
</div>
@endsection
