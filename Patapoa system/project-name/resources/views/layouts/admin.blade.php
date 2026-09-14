<!DOCTYPE html>
<html class="light" lang="en">
<head>
    <meta charset="utf-8"/>
    <meta content="width=device-width, initial-scale=1.0" name="viewport"/>
    <link rel="icon" type="image/x-icon" href="{{ asset('favicon.ico') }}">
    <title>{{ config('app.name', 'Patapoa') }} Admin - @yield('title')</title>
    <script src="https://cdn.tailwindcss.com?plugins=forms,container-queries"></script>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800;900&amp;display=swap" rel="stylesheet"/>
    <link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght,FILL@100..700,0..1&amp;display=swap" rel="stylesheet"/>
    <script id="tailwind-config">
        tailwind.config = {
            darkMode: "class",
            theme: {
                extend: {
                    "colors": {
                        "primary": "#006d3b",
                        "primary-container": "#00d177",
                        "on-primary-container": "#00532c",
                        "secondary": "#5d5e61",
                        "tertiary": "#124af0",
                        "background": "#f7faf9",
                        "surface": "#f7faf9",
                        "on-surface": "#181c1c",
                        "on-surface-variant": "#3c4a3f",
                        "surface-container": "#ebeeed",
                        "surface-container-low": "#f1f4f3",
                        "surface-container-high": "#e6e9e8",
                        "surface-container-highest": "#e0e3e2",
                        "surface-container-lowest": "#ffffff",
                        "outline-variant": "#bbcbbb",
                        "error": "#ba1a1a",
                        "error-container": "#ffdad6",
                    }
                }
            }
        }
    </script>
    <style>
        .material-symbols-outlined {
            font-variation-settings: 'FILL' 0, 'wght' 400, 'GRAD' 0, 'opsz' 24;
        }
        body { font-family: 'Inter', sans-serif; }
        .active-nav {
            color: #006d3b;
            font-weight: 700;
            border-right-width: 4px;
            border-right-color: #006d3b;
            background-color: rgba(0, 209, 119, 0.1);
        }
    </style>
    @stack('styles')
</head>
<body class="bg-background text-on-background antialiased flex">
    <!-- SideNavBar -->
    <aside class="hidden md:flex h-screen w-64 fixed left-0 top-0 bg-surface-container flex-col py-lg border-r border-outline-variant z-50">
        <div class="px-6 mb-8">
            <h1 class="text-2xl font-black text-primary">Patapoa</h1>
            <p class="text-xs uppercase tracking-widest text-on-surface-variant font-bold">Platform Controller</p>
        </div>
        <nav class="flex-1 px-3 space-y-1">
            <a href="{{ route('admin.dashboard') }}" class="flex items-center gap-3 px-4 py-3 rounded-lg transition-all {{ request()->routeIs('admin.dashboard') ? 'active-nav' : 'text-on-surface-variant font-medium hover:bg-surface-container-highest' }}">
                <span class="material-symbols-outlined">dashboard</span>
                <span class="text-sm">Overview</span>
            </a>
            <a href="{{ route('admin.orders') }}" class="flex items-center gap-3 px-4 py-3 rounded-lg transition-all {{ request()->routeIs('admin.orders') ? 'active-nav' : 'text-on-surface-variant font-medium hover:bg-surface-container-highest' }}">
                <span class="material-symbols-outlined">shopping_cart</span>
                <span class="text-sm">Orders</span>
            </a>
            <a href="{{ route('admin.merchants') }}" class="flex items-center gap-3 px-4 py-3 rounded-lg transition-all {{ request()->routeIs('admin.merchants') ? 'active-nav' : 'text-on-surface-variant font-medium hover:bg-surface-container-highest' }}">
                <span class="material-symbols-outlined">storefront</span>
                <span class="text-sm">Merchants</span>
            </a>
            <a href="{{ route('admin.deliveries') }}" class="flex items-center gap-3 px-4 py-3 rounded-lg transition-all {{ request()->routeIs('admin.deliveries') ? 'active-nav' : 'text-on-surface-variant font-medium hover:bg-surface-container-highest' }}">
                <span class="material-symbols-outlined">local_shipping</span>
                <span class="text-sm">Deliverers</span>
            </a>
            <a href="{{ route('admin.transactions') }}" class="flex items-center gap-3 px-4 py-3 rounded-lg transition-all {{ request()->routeIs('admin.transactions') ? 'active-nav' : 'text-on-surface-variant font-medium hover:bg-surface-container-highest' }}">
                <span class="material-symbols-outlined">receipt_long</span>
                <span class="text-sm">Transactions</span>
            </a>
            <a href="{{ route('admin.security') }}" class="flex items-center gap-3 px-4 py-3 rounded-lg transition-all {{ request()->routeIs('admin.security') ? 'active-nav' : 'text-on-surface-variant font-medium hover:bg-surface-container-highest' }}">
                <span class="material-symbols-outlined">security</span>
                <span class="text-sm">Security Hub</span>
            </a>
            <a href="{{ route('admin.settings') }}" class="flex items-center gap-3 px-4 py-3 rounded-lg transition-all {{ request()->routeIs('admin.settings') ? 'active-nav' : 'text-on-surface-variant font-medium hover:bg-surface-container-highest' }}">
                <span class="material-symbols-outlined">settings</span>
                <span class="text-sm">Settings</span>
            </a>
        </nav>
        <div class="px-3 pt-6 border-t border-outline-variant space-y-1">
            <a href="#" class="flex items-center gap-3 px-4 py-3 rounded-lg transition-all text-on-surface-variant font-medium hover:bg-surface-container-highest">
                <span class="material-symbols-outlined">contact_support</span>
                <span class="text-sm">Support</span>
            </a>
            <form action="{{ route('admin.logout') }}" method="POST">
                @csrf
                <button type="submit" class="w-full flex items-center gap-3 px-4 py-3 rounded-lg transition-all text-on-surface-variant font-medium hover:bg-surface-container-highest">
                    <span class="material-symbols-outlined">logout</span>
                    <span class="text-sm text-left">Logout</span>
                </button>
            </form>
        </div>
    </aside>

    <!-- Main Content -->
    <main class="flex-1 md:ml-64 min-h-screen flex flex-col">
        <!-- TopNavBar -->
        <header class="bg-surface shadow-sm w-full h-16 flex justify-between items-center px-6 sticky top-0 z-40">
            <div class="flex items-center gap-6 flex-1">
                <div class="relative w-full max-w-md">
                    <span class="material-symbols-outlined absolute left-4 top-1/2 -translate-y-1/2 text-on-surface-variant text-[20px]">search</span>
                    <input class="w-full pl-12 pr-4 py-2 bg-surface-container-low border-none rounded-full focus:ring-2 focus:ring-primary/20 text-sm" placeholder="Search platform data..." type="text"/>
                </div>
            </div>
            <div class="flex items-center gap-4">
                <button class="w-10 h-10 rounded-full flex items-center justify-center hover:bg-surface-container-high transition-colors">
                    <span class="material-symbols-outlined text-primary">notifications</span>
                </button>
                <div class="h-8 w-8 rounded-full overflow-hidden border border-outline-variant">
                    <img class="w-full h-full object-cover" src="https://ui-avatars.com/api/?name=Admin&background=006d3b&color=fff" alt="Admin"/>
                </div>
            </div>
        </header>

        <!-- Page Content -->
        <div class="p-6 space-y-6">
            @if(session('error'))
                <div class="bg-red-500/10 border border-red-500/50 text-red-500 px-6 py-4 rounded-2xl flex items-center gap-3">
                    <span class="material-symbols-outlined">error</span>
                    <span class="text-sm font-bold">{{ session('error') }}</span>
                </div>
            @endif

            @if(session('success'))
                <div class="bg-emerald-500/10 border border-emerald-500/50 text-emerald-500 px-6 py-4 rounded-2xl flex items-center gap-3">
                    <span class="material-symbols-outlined">check_circle</span>
                    <span class="text-sm font-bold">{{ session('success') }}</span>
                </div>
            @endif

            @if(session('warning'))
                <div class="bg-amber-500/10 border border-amber-500/50 text-amber-500 px-6 py-4 rounded-2xl flex items-center gap-3">
                    <span class="material-symbols-outlined">warning</span>
                    <span class="text-sm font-bold">{{ session('warning') }}</span>
                </div>
            @endif

            @yield('content')
        </div>
    </main>

    <!-- Mobile Navigation -->
    <nav class="md:hidden fixed bottom-0 left-0 w-full bg-surface flex justify-around items-center h-16 shadow-[0_-4px_16px_rgba(0,0,0,0.05)] px-4 z-50">
        <a href="{{ route('admin.dashboard') }}" class="flex flex-col items-center gap-1 {{ request()->routeIs('admin.dashboard') ? 'text-primary font-bold' : 'text-on-surface-variant' }}">
            <span class="material-symbols-outlined text-xl">dashboard</span>
            <span class="text-[10px]">Overview</span>
        </a>
        <a href="{{ route('admin.merchants') }}" class="flex flex-col items-center gap-1 {{ request()->routeIs('admin.merchants') ? 'text-primary font-bold' : 'text-on-surface-variant' }}">
            <span class="material-symbols-outlined text-xl">storefront</span>
            <span class="text-[10px]">Merchants</span>
        </a>
        <a href="{{ route('admin.deliveries') }}" class="flex flex-col items-center gap-1 {{ request()->routeIs('admin.deliveries') ? 'text-primary font-bold' : 'text-on-surface-variant' }}">
            <span class="material-symbols-outlined text-xl">local_shipping</span>
            <span class="text-[10px]">Riders</span>
        </a>
        <a href="{{ route('admin.transactions') }}" class="flex flex-col items-center gap-1 {{ request()->routeIs('admin.transactions') ? 'text-primary font-bold' : 'text-on-surface-variant' }}">
            <span class="material-symbols-outlined text-xl">receipt_long</span>
            <span class="text-[10px]">Finance</span>
        </a>
    </nav>

    @stack('scripts')
</body>
</html>
