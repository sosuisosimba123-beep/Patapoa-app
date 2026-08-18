@extends('layouts.admin')

@section('title', 'System Settings')

@section('content')
<div class="space-y-1">
    <h2 class="text-3xl font-black text-on-surface">System Configuration</h2>
    <p class="text-lg text-on-surface-variant">Control platform-wide logistics, pricing, and operational rules.</p>
</div>

<div class="grid grid-cols-1 lg:grid-cols-2 gap-8 mt-8">
    <!-- Pricing Rules -->
    <div class="bg-white p-6 rounded-xl border border-outline-variant shadow-sm">
        <h3 class="text-xl font-bold mb-6 flex items-center gap-2">
            <span class="material-symbols-outlined text-primary">payments</span>
            Delivery Pricing Rules
        </h3>

        <form action="{{ route('admin.settings.pricing') }}" method="POST" class="space-y-4">
            @csrf
            <div class="grid grid-cols-2 gap-4">
                <div class="col-span-2">
                    <label class="text-xs font-bold uppercase tracking-wider text-on-surface-variant">Zone Name</label>
                    <select name="zone_name" class="w-full p-2 border rounded-lg mt-1">
                        <option value="Moshi">Moshi</option>
                        <option value="Dar es Salaam">Dar es Salaam</option>
                    </select>
                </div>
                <div>
                    <label class="text-xs font-bold uppercase tracking-wider text-on-surface-variant">Base Fee (TSH)</label>
                    <input type="number" name="base_fee" value="2000" class="w-full p-2 border rounded-lg mt-1">
                </div>
                <div>
                    <label class="text-xs font-bold uppercase tracking-wider text-on-surface-variant">Per KM Fee (TSH)</label>
                    <input type="number" name="per_km_fee" value="500" class="w-full p-2 border rounded-lg mt-1">
                </div>
                <div>
                    <label class="text-xs font-bold uppercase tracking-wider text-on-surface-variant">Surge Multiplier</label>
                    <input type="number" step="0.1" name="surge_multiplier" value="1.0" class="w-full p-2 border rounded-lg mt-1">
                </div>
                <div>
                    <label class="text-xs font-bold uppercase tracking-wider text-on-surface-variant">Max Distance (KM)</label>
                    <input type="number" step="0.5" name="max_distance" value="15.0" class="w-full p-2 border rounded-lg mt-1">
                </div>
                <div class="col-span-2">
                    <label class="text-xs font-bold uppercase tracking-wider text-on-surface-variant">Free Over (TSH)</label>
                    <input type="number" name="min_basket_value_for_free_delivery" placeholder="Optional" class="w-full p-2 border rounded-lg mt-1">
                </div>
            </div>
            <button type="submit" class="w-full bg-primary text-on-primary font-bold py-3 rounded-xl mt-4 shadow-md hover:bg-primary/90 transition-all">
                Update Pricing Strategy
            </button>
        </form>

        <div class="mt-8">
            <h4 class="text-sm font-bold text-on-surface mb-4">Active Pricing Policies</h4>
            <div class="space-y-3">
                @foreach($pricingRules as $rule)
                <div class="p-3 bg-surface-container-low rounded-lg border border-outline-variant flex justify-between items-center">
                    <div>
                        <p class="font-bold">{{ $rule->zone_name }}</p>
                        <p class="text-xs text-on-surface-variant">Base: {{ number_format($rule->base_fee) }} • KM: {{ number_format($rule->per_km_fee) }} • Max: {{ $rule->max_distance }}km</p>
                    </div>
                    <div class="text-right">
                        <span class="px-2 py-1 bg-primary/10 text-primary text-[10px] font-bold rounded">x{{ $rule->surge_multiplier }}</span>
                    </div>
                </div>
                @endforeach
            </div>
        </div>
    </div>

    <!-- Operational Zones -->
    <div class="bg-white p-6 rounded-xl border border-outline-variant shadow-sm">
        <h3 class="text-xl font-bold mb-6 flex items-center gap-2">
            <span class="material-symbols-outlined text-secondary">location_city</span>
            Operational Radius
        </h3>

        <div class="space-y-4">
            @forelse($pricingRules as $rule)
            <div class="p-4 bg-surface-container rounded-xl">
                <div class="flex justify-between items-center mb-2">
                    <span class="font-bold">{{ $rule->zone_name }}</span>
                    <span class="text-xs font-bold text-primary">{{ $rule->max_distance }} KM Radius</span>
                </div>
                <div class="w-full bg-outline-variant h-2 rounded-full overflow-hidden">
                    <div class="bg-primary h-full" style="width: {{ min(($rule->max_distance / 30) * 100, 100) }}%"></div>
                </div>
            </div>
            @empty
            <p class="text-on-surface-variant italic">No operational zones configured.</p>
            @endforelse
        </div>

        <div class="mt-12 p-6 bg-tertiary/10 rounded-2xl border border-tertiary/20">
            <h4 class="font-black text-tertiary flex items-center gap-2 mb-4">
                <span class="material-symbols-outlined">payments</span>
                Commission & Platform Fees
            </h4>

            <form action="{{ route('admin.settings.platform') }}" method="POST" class="space-y-4">
                @csrf
                <div class="grid grid-cols-1 gap-4">
                    <div>
                        <label class="text-xs font-bold uppercase tracking-wider text-on-surface-variant">Default Merchant Commission (%)</label>
                        <div class="flex items-center gap-2">
                            <input type="number" step="0.1" name="merchant_commission_rate" value="{{ ($platformSettings['merchant_commission_rate'] ?? 0.05) * 100 }}" class="w-full p-2 border rounded-lg mt-1">
                            <span class="font-bold text-on-surface-variant">%</span>
                        </div>
                    </div>
                    <div>
                        <label class="text-xs font-bold uppercase tracking-wider text-on-surface-variant">Rider Fee Commission (%)</label>
                        <div class="flex items-center gap-2">
                            <input type="number" step="0.1" name="rider_commission_rate" value="{{ ($platformSettings['rider_commission_rate'] ?? 0.05) * 100 }}" class="w-full p-2 border rounded-lg mt-1">
                            <span class="font-bold text-on-surface-variant">%</span>
                        </div>
                    </div>
                    <div>
                        <label class="text-xs font-bold uppercase tracking-wider text-on-surface-variant">Fixed Convenience Fee (TSH)</label>
                        <input type="number" name="convenience_fee" value="{{ $platformSettings['convenience_fee'] ?? 0 }}" class="w-full p-2 border rounded-lg mt-1">
                    </div>
                </div>
                <button type="submit" class="w-full bg-tertiary text-on-tertiary font-bold py-3 rounded-xl mt-4 shadow-md hover:bg-tertiary/90 transition-all">
                    Update Commission Rates
                </button>
            </form>

            <p class="text-xs text-on-surface-variant mt-4 italic">
                Note: Individual merchants can have custom commission overrides set in their profiles.
            </p>
        </div>
    </div>
</div>
@endsection
