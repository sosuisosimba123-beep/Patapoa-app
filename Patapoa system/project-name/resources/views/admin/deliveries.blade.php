@extends('layouts.admin')

@section('title', 'Deliverer Fleet')

@section('content')
<!-- Header Section -->
<div class="flex justify-between items-end">
    <div>
        <h2 class="text-3xl font-black text-on-surface">Deliverer Fleet</h2>
        <p class="text-lg text-on-surface-variant mt-1">Managing partners in the Tanzanian logistics network.</p>
    </div>
    <button onclick="toggleRiderForm()" class="flex items-center gap-2 bg-primary text-on-primary px-6 py-2 rounded-xl font-bold hover:brightness-95 transition-all shadow-md active:scale-95">
        <span class="material-symbols-outlined">add_circle</span>
        Add Rider
    </button>
</div>

<!-- Add Rider Form (Hidden by default) -->
<div id="riderForm" class="hidden bg-white p-6 rounded-xl border border-primary/20 shadow-lg mt-6">
    <h3 class="text-lg font-bold mb-4">Onboard New Delivery Partner</h3>
    <form action="{{ route('admin.riders.store') }}" method="POST">
        @csrf
        <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
            <input type="text" name="name" placeholder="Full Name" required class="p-2 border rounded-lg">
            <input type="text" name="phone" placeholder="Phone Number" required class="p-2 border rounded-lg">
            <input type="password" name="password" placeholder="Password" required class="p-2 border rounded-lg">
            <input type="text" name="city" placeholder="City (e.g. Moshi)" required class="p-2 border rounded-lg">
            <select name="vehicle_type" class="p-2 border rounded-lg">
                <option value="motorcycle">Motorcycle</option>
                <option value="bicycle">Bicycle</option>
                <option value="car">Car</option>
            </select>
            <button type="submit" class="bg-primary text-on-primary font-bold rounded-lg py-2">Create Partner</button>
        </div>
    </form>
</div>

<!-- Active Deliveries Section -->
<div class="mt-12">
    <h3 class="text-xl font-black text-on-surface mb-6">Live Deliveries</h3>
    <div class="grid grid-cols-1 gap-4">
        @forelse($activeDeliveries as $delivery)
        <div class="bg-white p-4 rounded-xl border border-outline-variant shadow-sm flex justify-between items-center">
            <div class="flex items-center gap-4">
                <div class="p-3 bg-primary/10 rounded-full text-primary">
                    <span class="material-symbols-outlined">directions_bike</span>
                </div>
                <div>
                    <h4 class="font-bold">Order {{ $delivery->display_id }}</h4>
                    <p class="text-xs text-on-surface-variant">Partner: {{ $delivery->deliveryPartner->user->name ?? 'Assigning...' }}</p>
                </div>
            </div>
            <div class="text-right">
                <span class="px-3 py-1 rounded-full text-[10px] font-bold uppercase tracking-widest bg-tertiary/10 text-tertiary">
                    {{ str_replace('_', ' ', $delivery->status) }}
                </span>
                <p class="text-xs mt-1 text-on-surface-variant">{{ $delivery->updated_at->diffForHumans() }}</p>
            </div>
        </div>
        @empty
        <p class="text-on-surface-variant text-center py-8 bg-surface-container-low rounded-xl border border-dashed">No active deliveries at the moment.</p>
        @endforelse
    </div>
</div>

<script>
    function toggleRiderForm() {
        const form = document.getElementById('riderForm');
        form.classList.toggle('hidden');
    }
</script>

<!-- KPIs Section -->
<div class="grid grid-cols-1 md:grid-cols-4 gap-4">
    <div class="bg-surface-container-low p-6 rounded-xl border border-outline-variant shadow-sm transition-transform hover:-translate-y-1">
        <div class="flex justify-between items-start mb-2">
            <span class="material-symbols-outlined text-primary text-3xl">groups</span>
        </div>
        <p class="text-xs uppercase tracking-widest text-on-surface-variant font-bold">Total Riders</p>
        <p class="text-3xl font-black text-on-surface mt-1">{{ $riders->total() }}</p>
    </div>
    <div class="bg-surface-container-low p-6 rounded-xl border border-outline-variant shadow-sm transition-transform hover:-translate-y-1">
        <div class="flex justify-between items-start mb-2">
            <span class="material-symbols-outlined text-primary-container text-3xl">sensors</span>
            <div class="flex items-center gap-1">
                <span class="w-2 h-2 rounded-full bg-primary-container animate-pulse"></span>
                <span class="text-primary-container font-bold text-xs">Live</span>
            </div>
        </div>
        <p class="text-xs uppercase tracking-widest text-on-surface-variant font-bold">Online Now</p>
        <p class="text-3xl font-black text-on-surface mt-1">{{ \App\Models\DeliveryPartner::where('is_online', true)->count() }}</p>
    </div>
    <div class="bg-surface-container-low p-6 rounded-xl border border-outline-variant shadow-sm transition-transform hover:-translate-y-1">
        <div class="flex justify-between items-start mb-2">
            <span class="material-symbols-outlined text-secondary text-3xl">star</span>
        </div>
        <p class="text-xs uppercase tracking-widest text-on-surface-variant font-bold">Average Rating</p>
        <p class="text-3xl font-black text-on-surface mt-1">{{ number_format($avgRating, 1) }}</p>
    </div>
    <div class="bg-surface-container-low p-6 rounded-xl border border-outline-variant shadow-sm transition-transform hover:-translate-y-1">
        <div class="flex justify-between items-start mb-2">
            <span class="material-symbols-outlined text-error text-3xl">payments</span>
        </div>
        <p class="text-xs uppercase tracking-widest text-on-surface-variant font-bold">Total Debt</p>
        <p class="text-3xl font-black text-error mt-1">TSH {{ number_format($totalDebt) }}</p>
    </div>
</div>

<!-- Deliverer Grid -->
<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
    @foreach($riders as $rider)
    <div class="bg-white p-4 rounded-xl flex flex-col gap-4 shadow-sm border border-outline-variant hover:border-primary transition-all group">
        <div class="flex items-start gap-4">
            <div class="relative">
                <img class="w-20 h-20 rounded-xl object-cover border-2 border-surface" src="https://ui-avatars.com/api/?name={{ urlencode($rider->user->name ?? 'Rider') }}&background=006d3b&color=fff"/>
                @if($rider->is_online)
                <span class="absolute -bottom-1 -right-1 w-4 h-4 bg-primary-container border-2 border-white rounded-full"></span>
                @endif
            </div>
            <div class="flex-1">
                <div class="flex justify-between items-start">
                    <h3 class="text-lg font-black text-on-surface">{{ $rider->user->name ?? 'Unknown Rider' }}</h3>
                    <form action="{{ route('admin.users.toggle-status', $rider->user_id) }}" method="POST">
                        @csrf
                        <button type="submit" class="material-symbols-outlined p-1 text-on-surface-variant hover:bg-surface-container-high rounded-full transition-colors {{ !$rider->user->is_active ? 'text-error' : '' }}" title="{{ $rider->user->is_active ? 'Suspend Rider' : 'Activate Rider' }}">
                            {{ $rider->user->is_active ? 'person_check' : 'person_off' }}
                        </button>
                    </form>
                </div>
                <div class="flex items-center gap-1 mt-1">
                    <span class="material-symbols-outlined text-xs text-on-surface-variant">{{ $rider->vehicle_type === 'car' ? 'directions_car' : ($rider->vehicle_type === 'bicycle' ? 'pedal_bike' : 'motorcycle') }}</span>
                    <span class="text-sm text-on-surface-variant capitalize">{{ $rider->vehicle_type }}</span>
                </div>
                <div class="flex items-center gap-1 mt-1 text-primary">
                    <span class="material-symbols-outlined text-sm">star</span>
                    <span class="text-sm font-bold">{{ number_format($rider->rating, 1) }}</span>
                </div>
            </div>
        </div>
        <div class="flex flex-wrap gap-2">
            <span class="px-3 py-1 rounded-full text-[10px] font-bold uppercase tracking-widest {{ $rider->is_online ? 'bg-primary/10 text-primary' : 'bg-secondary/10 text-secondary' }}">
                {{ $rider->is_online ? 'Available' : 'Offline' }}
            </span>
            @if(!$rider->is_verified)
            <form action="{{ route('admin.riders.verify', $rider->id) }}" method="POST">
                @csrf
                <button type="submit" class="px-3 py-1 bg-tertiary text-on-tertiary text-[10px] font-bold rounded-full shadow hover:brightness-95">
                    VERIFY NOW
                </button>
            </form>
            @else
            <span class="px-3 py-1 rounded-full bg-primary/5 text-primary text-[10px] font-bold border border-primary/10 uppercase tracking-widest">
                VERIFIED
            </span>
            @endif
        </div>
        <div class="border-t border-outline-variant pt-4 flex justify-between items-center">
            <div>
                <p class="text-[10px] uppercase tracking-widest text-on-surface-variant font-bold">Completed Trips</p>
                <p class="text-lg font-black text-on-surface">{{ $rider->orders_count }}</p>
            </div>
            <a href="{{ route('admin.transactions', ['type' => 'earning', 'user_id' => $rider->user_id]) }}" class="text-primary text-[10px] font-bold uppercase tracking-widest hover:underline">View Ledger</a>
        </div>
    </div>
    @endforeach
</div>

<!-- Footer Pagination -->
<div class="mt-6">
    {{ $riders->links() }}
</div>
@endsection
