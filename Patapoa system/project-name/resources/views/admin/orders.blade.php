@extends('layouts.admin')

@section('title', 'Order Management')

@section('content')
<div class="flex justify-between items-end">
    <div>
        <h2 class="text-3xl font-black text-on-surface">Order Queue</h2>
        <p class="text-on-surface-variant font-medium">Monitor and manage customer transactions.</p>
    </div>
</div>

<div class="bg-white rounded-xl shadow-lg border border-outline-variant overflow-hidden mt-8">
    <div class="overflow-x-auto">
        <table class="w-full text-left">
            <thead>
                <tr class="bg-surface-container-highest border-b border-outline-variant">
                    <th class="px-6 py-3 text-xs font-bold uppercase tracking-widest text-on-surface-variant">Order ID</th>
                    <th class="px-6 py-3 text-xs font-bold uppercase tracking-widest text-on-surface-variant">Customer</th>
                    <th class="px-6 py-3 text-xs font-bold uppercase tracking-widest text-on-surface-variant text-right">Net Platform Fee</th>
                    <th class="px-6 py-3 text-xs font-bold uppercase tracking-widest text-on-surface-variant text-right">Total</th>
                    <th class="px-6 py-3 text-xs font-bold uppercase tracking-widest text-on-surface-variant">Payment</th>
                    <th class="px-6 py-3 text-xs font-bold uppercase tracking-widest text-on-surface-variant">Status</th>
                    <th class="px-6 py-3 text-xs font-bold uppercase tracking-widest text-on-surface-variant text-center">Actions</th>
                </tr>
            </thead>
            <tbody class="divide-y divide-outline-variant">
                @foreach($orders as $order)
                <tr class="hover:bg-primary/5 transition-colors">
                    <td class="px-6 py-4 text-sm font-bold text-primary">{{ $order->display_id }}</td>
                    <td class="px-6 py-4 text-sm">{{ $order->customer->name ?? 'Unknown' }}</td>
                    <td class="px-6 py-4 text-sm font-bold text-right text-green-600">TZS {{ number_format($order->platform_fee) }}</td>
                    <td class="px-6 py-4 text-sm font-black text-right">TZS {{ number_format($order->total) }}</td>
                    <td class="px-6 py-4">
                        <span class="px-3 py-1 rounded-full text-[10px] font-bold uppercase tracking-widest {{ $order->payment_status === 'paid' ? 'bg-green-100 text-green-700' : 'bg-yellow-100 text-yellow-700' }}">
                            {{ $order->payment_status }}
                        </span>
                    </td>
                    <td class="px-6 py-4">
                        <span class="px-3 py-1 rounded-full text-[10px] font-bold uppercase tracking-widest bg-blue-50 text-blue-700 border border-blue-100">
                            {{ $order->status }}
                        </span>
                    </td>
                    <td class="px-6 py-4 text-center">
                        @if($order->payment_status !== 'paid')
                        <form action="{{ route('admin.orders.mark-paid', $order->id) }}" method="POST" class="inline">
                            @csrf
                            <button type="submit" class="bg-primary text-on-primary text-[10px] font-bold px-3 py-1 rounded-lg shadow hover:bg-primary/90">
                                CONFIRM PAYMENT
                            </button>
                        </form>
                        @else
                        <span class="text-xs text-on-surface-variant">Verified</span>
                        @endif
                    </td>
                </tr>
                @endforeach
            </tbody>
        </table>
    </div>
    <div class="px-6 py-4 bg-surface-container/10 border-t border-outline-variant/20">
        {{ $orders->links() }}
    </div>
</div>
@endsection
