<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="icon" type="image/x-icon" href="{{ asset('favicon.ico') }}">
    <title>Patapoa Admin Login</title>
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-slate-950 h-screen flex items-center justify-center">
    <div class="bg-slate-900 border border-slate-800 p-8 rounded-2xl shadow-2xl w-96 text-center">
        <div class="flex justify-center mb-6">
            <div class="w-12 h-12 rounded-xl bg-emerald-500 flex items-center justify-center font-bold text-2xl text-white shadow-lg shadow-emerald-500/20">
                P
            </div>
        </div>

        <h1 class="text-2xl font-bold mb-2 text-white">Admin Portal</h1>
        <p class="text-slate-400 text-sm mb-8">Authorize your session via PocketBase</p>

        @if(session('error'))
            <div class="bg-red-500/10 border border-red-500/50 text-red-500 px-4 py-3 rounded-xl mb-6 text-sm text-left">
                {{ session('error') }}
            </div>
        @endif

        @if(session('success'))
            <div class="bg-emerald-500/10 border border-emerald-500/50 text-emerald-400 px-4 py-3 rounded-xl mb-6 text-sm text-left">
                {{ session('success') }}
            </div>
        @endif

        <form action="{{ route('admin.authenticate') }}" method="POST" class="space-y-4">
            @csrf
            <div class="text-left">
                <label class="block text-xs font-semibold text-slate-500 uppercase tracking-wider mb-1.5 ml-1">Email Address</label>
                <input type="email" name="email" required
                       class="w-full bg-slate-950 border border-slate-800 rounded-xl px-4 py-3 text-white placeholder-slate-600 focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500/50 transition"
                       placeholder="admin@patapoa.online">
            </div>

            <div class="text-left">
                <label class="block text-xs font-semibold text-slate-500 uppercase tracking-wider mb-1.5 ml-1">Password</label>
                <input type="password" name="password" required
                       class="w-full bg-slate-950 border border-slate-800 rounded-xl px-4 py-3 text-white placeholder-slate-600 focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500/50 transition"
                       placeholder="••••••••">
            </div>

            <button type="submit"
                    class="w-full bg-emerald-600 hover:bg-emerald-500 text-white font-bold py-3.5 px-4 rounded-xl transition duration-200 shadow-lg shadow-emerald-600/10 mt-2">
                Begin Verification
            </button>
        </form>

        <div class="mt-8 pt-6 border-t border-slate-800">
            <div class="flex items-center justify-center gap-2 text-[10px] text-slate-500 uppercase tracking-widest font-bold">
                <span class="w-1.5 h-1.5 rounded-full bg-emerald-500"></span>
                PocketBase Security Active
            </div>
        </div>
    </div>
</body>
</html>
