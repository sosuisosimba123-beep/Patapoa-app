@extends('layouts.admin')

@section('title', 'Security Hub')

@section('content')
<div class="bg-[#0f172a] text-white -m-6 p-6 min-h-screen">
    <!-- Header -->
    <div class="flex items-center justify-between mb-8">
        <div class="flex items-center gap-4">
            <div class="p-3 bg-blue-600 rounded-xl">
                <span class="material-symbols-outlined text-white">security</span>
            </div>
            <div>
                <div class="flex items-center gap-2">
                    <h1 class="text-2xl font-bold">Security Hub</h1>
                    <span class="px-2 py-0.5 bg-blue-500/20 text-blue-400 text-[10px] font-bold rounded border border-blue-500/30">LIVE</span>
                </div>
                <div class="flex items-center gap-2 text-xs text-gray-400">
                    <span class="w-2 h-2 bg-green-500 rounded-full animate-pulse"></span>
                    <span>Monitoring</span>
                    <span>•</span>
                    <span>api-gw-01</span>
                </div>
            </div>
        </div>
        <div class="flex items-center gap-4">
            <button class="flex items-center gap-2 px-4 py-2 bg-slate-800 rounded-lg text-sm border border-slate-700">
                <span class="material-symbols-outlined text-sm">notifications</span>
                <span>3</span>
            </button>
            <button class="flex items-center gap-2 px-4 py-2 bg-red-500/20 text-red-400 rounded-lg text-sm border border-red-500/30">
                <span class="material-symbols-outlined text-sm">warning</span>
                <span>{{ $activeAlertsCount }}</span>
            </button>
        </div>
    </div>

    <!-- Tabs -->
    <div class="flex items-center gap-8 mb-8 border-b border-slate-800">
        <button class="pb-4 text-blue-400 border-b-2 border-blue-400 font-medium flex items-center gap-2">
            <span class="material-symbols-outlined text-xl">grid_view</span>
            <span>Alerts</span>
        </button>
        <button class="pb-4 text-gray-400 hover:text-white transition-colors flex items-center gap-2">
            <span class="material-symbols-outlined text-xl">search</span>
            <span>Investigate</span>
        </button>
        <button class="pb-4 text-gray-400 hover:text-white transition-colors flex items-center gap-2">
            <span class="material-symbols-outlined text-xl">shield</span>
            <span>Respond</span>
        </button>
    </div>

    <!-- SOC Lead Message -->
    <div class="flex gap-4 mb-8">
        <div class="w-12 h-12 rounded-full bg-blue-900 flex items-center justify-center text-blue-400 font-bold border border-blue-500/30">
            SO
        </div>
        <div class="flex-1">
            <div class="flex items-center gap-2 mb-1">
                <span class="font-bold text-sm">Sam Osei</span>
                <span class="text-[10px] text-gray-400 uppercase tracking-widest font-bold">SOC LEAD</span>
            </div>
            <div class="bg-[#1e293b] p-6 rounded-2xl rounded-tl-none border border-slate-700 relative shadow-xl">
                <p class="text-gray-300">
                    Hey, glad you're here. The alarms are going, someone is trying to hack us. Can you help investigate?
                </p>
                <div class="absolute -left-2 top-0 w-4 h-4 bg-[#1e293b] rotate-45 border-l border-t border-slate-700"></div>
            </div>
        </div>
    </div>

    <!-- Summary Cards -->
    <div class="grid grid-cols-1 md:grid-cols-2 gap-6 mb-8">
        <div class="bg-[#1e293b] p-6 rounded-3xl border border-slate-700 shadow-xl">
            <div class="flex justify-between items-start mb-6">
                <div class="flex items-center gap-4">
                    <div class="p-3 bg-red-500/10 rounded-2xl">
                        <span class="material-symbols-outlined text-red-500">notifications</span>
                    </div>
                    <div>
                        <h3 class="text-3xl font-bold">{{ $activeAlertsCount }}</h3>
                        <p class="text-xs text-gray-400">Alert needs you</p>
                    </div>
                </div>
                <div class="flex items-center gap-1 text-red-400 text-xs font-bold">
                    <span class="material-symbols-outlined text-xs">trending_up</span>
                    <span>+1</span>
                </div>
            </div>
            <div class="flex items-end gap-1 h-12">
                @foreach([20, 30, 15, 25, 40, 35, 50, 45, 60] as $h)
                <div class="flex-1 bg-red-600 rounded-sm" style="height: {{ $h }}%"></div>
                @endforeach
            </div>
        </div>

        <div class="bg-[#1e293b] p-6 rounded-3xl border border-slate-700 shadow-xl">
            <div class="flex justify-between items-start mb-6">
                <div class="flex items-center gap-4">
                    <div class="p-3 bg-blue-500/10 rounded-2xl">
                        <span class="material-symbols-outlined text-blue-500">dns</span>
                    </div>
                    <div>
                        <h3 class="text-3xl font-bold">{{ $systemsWatched }}</h3>
                        <p class="text-xs text-gray-400">Systems watched</p>
                    </div>
                </div>
            </div>
            <div class="flex items-end gap-1 h-12">
                @foreach([40, 45, 42, 38, 44, 46, 43, 41, 47] as $h)
                <div class="flex-1 bg-blue-600 rounded-sm" style="height: {{ $h }}%"></div>
                @endforeach
            </div>
        </div>
    </div>

    <!-- Alerts List -->
    <div class="space-y-4">
        @foreach($alerts as $alert)
        <div class="bg-[#1e293b] rounded-3xl border {{ $alert->type === 'critical' ? 'border-red-500/50' : 'border-slate-700' }} overflow-hidden shadow-2xl">
            <div class="p-6">
                <div class="flex items-start justify-between mb-4">
                    <div class="flex items-center gap-2">
                        <span class="px-2 py-1 bg-red-500/20 text-red-400 text-[10px] font-bold rounded uppercase">{{ $alert->type }}</span>
                        <span class="px-2 py-1 bg-slate-800 text-gray-400 text-[10px] font-bold rounded uppercase">NL</span>
                    </div>
                    <div class="flex items-center gap-2">
                        <form action="{{ route('admin.security.resolve', $alert->id) }}" method="POST">
                            @csrf
                            <button type="submit" class="flex items-center gap-2 px-4 py-2 bg-slate-800 hover:bg-slate-700 rounded-xl text-xs font-bold transition-colors">
                                <span class="material-symbols-outlined text-sm">check_circle</span>
                                <span>Resolve</span>
                            </button>
                        </form>
                        <button class="flex items-center gap-2 px-4 py-2 bg-red-600 hover:bg-red-700 rounded-xl text-xs font-bold transition-colors">
                            <span>Investigate</span>
                            <span class="material-symbols-outlined text-sm">arrow_forward</span>
                        </button>
                    </div>
                </div>
                <h2 class="text-xl font-bold mb-2">{{ $alert->title }}</h2>
                <p class="text-gray-400 text-sm mb-4 max-w-2xl">
                    {{ $alert->description }}
                </p>
                <div class="flex items-center gap-4 text-xs">
                    <div class="flex items-center gap-2 text-gray-400">
                        <span>Coming from</span>
                        <span class="text-red-400 font-mono font-bold">{{ $alert->source_ip }}</span>
                        <button class="material-symbols-outlined text-sm hover:text-white">content_copy</button>
                    </div>
                </div>
            </div>
            @if($alert->type === 'critical')
            <div class="h-1 bg-gradient-to-r from-red-600 via-red-500 to-transparent"></div>
            @endif
        </div>
        @endforeach
    </div>
</div>
@endsection

@push('styles')
<style>
    /* Override layout styles for this specific page if needed */
    main { background-color: #0f172a !important; }
    header { background-color: #0f172a !important; border-bottom: 1px solid #1e293b; }
    header input { background-color: #1e293b !important; color: white; }
    header .material-symbols-outlined { color: #94a3b8 !important; }
</style>
@endpush
