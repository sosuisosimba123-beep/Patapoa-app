@extends('layouts.admin')

@section('title', 'Transaction Ledger')

@section('content')
<!-- Header -->
<div class="flex justify-between items-end">
    <div>
        <h2 class="text-3xl font-black text-on-surface">Transaction Ledger</h2>
        <p class="text-on-surface-variant font-medium">Comprehensive financial record of platform commerce.</p>
    </div>
    <div class="flex gap-2">
        <form action="{{ route('admin.transactions') }}" method="GET" class="flex gap-2">
            <select name="type" onchange="this.form.submit()" class="px-4 py-2 rounded-xl border border-outline bg-white font-bold text-xs">
                <option value="all">All Types</option>
                <option value="payment" {{ request('type') == 'payment' ? 'selected' : '' }}>Payments</option>
                <option value="payout" {{ request('type') == 'payout' ? 'selected' : '' }}>Payouts</option>
                <option value="earning" {{ request('type') == 'earning' ? 'selected' : '' }}>Earnings</option>
            </select>
            <select name="status" onchange="this.form.submit()" class="px-4 py-2 rounded-xl border border-outline bg-white font-bold text-xs">
                <option value="all">All Status</option>
                <option value="completed" {{ request('status') == 'completed' ? 'selected' : '' }}>Completed</option>
                <option value="pending" {{ request('status') == 'pending' ? 'selected' : '' }}>Pending</option>
                <option value="failed" {{ request('status') == 'failed' ? 'selected' : '' }}>Failed</option>
            </select>
        </form>
        <a href="{{ route('admin.transactions', array_merge(request()->all(), ['export' => 1])) }}" class="flex items-center gap-2 px-6 py-2 rounded-xl bg-primary text-on-primary hover:opacity-90 transition-opacity font-bold">
            <span class="material-symbols-outlined text-[18px]">download</span>
            Export CSV
        </a>
    </div>
</div>

<!-- Summary Cards -->
<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
    <div class="bg-white p-6 rounded-xl shadow-sm border border-outline-variant flex flex-col justify-between hover:shadow-md transition-shadow">
        <div class="flex justify-between">
            <span class="text-xs uppercase tracking-widest text-on-surface-variant font-bold">Total Sales (Gross)</span>
            <span class="material-symbols-outlined text-primary">payments</span>
        </div>
        <div>
            <p class="text-2xl font-black text-on-surface">TZS {{ number_format($summary['total_sales']) }}</p>
        </div>
    </div>
    <div class="bg-primary-container/10 p-6 rounded-xl shadow-sm border border-primary-container flex flex-col justify-between hover:shadow-md transition-shadow">
        <div class="flex justify-between">
            <span class="text-xs uppercase tracking-widest text-on-primary-container font-bold">Platform Revenue (5% Net)</span>
            <span class="material-symbols-outlined text-primary">account_balance_wallet</span>
        </div>
        <div>
            <p class="text-2xl font-black text-primary">TZS {{ number_format($summary['platform_revenue']) }}</p>
        </div>
    </div>
    <div class="bg-white p-6 rounded-xl shadow-sm border border-outline-variant flex flex-col justify-between hover:shadow-md transition-shadow">
        <div class="flex justify-between">
            <span class="text-xs uppercase tracking-widest text-on-surface-variant font-bold">Pending Payouts</span>
            <span class="material-symbols-outlined text-secondary">hourglass_empty</span>
        </div>
        <div>
            <p class="text-2xl font-black text-on-surface">TZS {{ number_format($summary['pending_payouts']) }}</p>
        </div>
    </div>
    <div class="bg-white p-6 rounded-xl shadow-sm border border-outline-variant flex flex-col justify-between hover:shadow-md transition-shadow">
        <div class="flex justify-between">
            <span class="text-xs uppercase tracking-widest text-on-surface-variant font-bold">Settled Payouts</span>
            <span class="material-symbols-outlined text-error">check_circle</span>
        </div>
        <div>
            <p class="text-2xl font-black text-green-600">TZS {{ number_format($summary['completed_payouts']) }}</p>
        </div>
    </div>
</div>

<!-- Main Transactions Table -->
<div class="bg-white rounded-xl shadow-lg border border-outline-variant overflow-hidden">
    <div class="p-4 border-b border-outline-variant flex justify-between items-center bg-surface-container-low">
        <h3 class="text-lg font-black">Transaction Logs</h3>
    </div>
    <div class="overflow-x-auto">
        <table class="w-full text-left">
            <thead>
                <tr class="bg-surface-container-highest border-b border-outline-variant">
                    <th class="px-6 py-3 text-xs font-bold uppercase tracking-widest text-on-surface-variant">Transaction ID</th>
                    <th class="px-6 py-3 text-xs font-bold uppercase tracking-widest text-on-surface-variant">Type</th>
                    <th class="px-6 py-3 text-xs font-bold uppercase tracking-widest text-on-surface-variant">User</th>
                    <th class="px-6 py-3 text-xs font-bold uppercase tracking-widest text-on-surface-variant text-right">Amount</th>
                    <th class="px-6 py-3 text-xs font-bold uppercase tracking-widest text-on-surface-variant text-center">Date</th>
                    <th class="px-6 py-3 text-xs font-bold uppercase tracking-widest text-on-surface-variant text-center">Status</th>
                </tr>
            </thead>
            <tbody class="divide-y divide-outline-variant">
                @foreach($transactions as $t)
                <tr class="hover:bg-primary/5 transition-colors cursor-pointer">
                    <td class="px-6 py-4 text-sm font-bold text-primary">PAT-T-{{ $t->id }}</td>
                    <td class="px-6 py-4">
                        <div class="flex items-center gap-2">
                            <span class="material-symbols-outlined text-primary text-[18px]">{{ $t->type === 'payment' ? 'shopping_bag' : 'send_money' }}</span>
                            <span class="text-sm font-medium capitalize">{{ $t->type }}</span>
                        </div>
                    </td>
                    <td class="px-6 py-4 text-sm">{{ $t->user->name ?? 'System' }}</td>
                    <td class="px-6 py-4 text-sm font-black text-right">TZS {{ number_format($t->amount) }}</td>
                    <td class="px-6 py-4 text-sm text-on-surface-variant text-center">{{ $t->created_at->format('M d, H:i') }}</td>
                    <td class="px-6 py-4 text-center">
                        <span class="px-3 py-1 rounded-full text-[10px] font-bold uppercase tracking-widest {{ $t->status === 'completed' ? 'bg-primary/10 text-primary border border-primary/20' : 'bg-secondary-container text-on-secondary-container border border-outline-variant' }}">
                            {{ $t->status }}
                        </span>
                    </td>
                </tr>
                @endforeach
            </tbody>
        </table>
    </div>
    <!-- Pagination Footer -->
    <div class="px-6 py-4 bg-surface-container/10 border-t border-outline-variant/20">
        {{ $transactions->links() }}
    </div>
</div>
@endsection
