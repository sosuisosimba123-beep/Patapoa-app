<!DOCTYPE html>
<html lang="sw" class="dark">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="icon" type="image/x-icon" href="{{ asset('favicon.ico') }}">
    <title>Patapoa Admin | Secure Login</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <script>
        tailwind.config = {
            darkMode: 'class',
            theme: {
                extend: {
                    colors: {
                        patapoa: {
                            orange: '#FF5722',
                            dark: '#0f172a',
                        }
                    }
                }
            }
        }
    </script>
    <style>
        .glass-panel {
            background: rgba(30, 41, 59, 0.6);
            backdrop-filter: blur(16px);
            -webkit-backdrop-filter: blur(16px);
            border: 1px solid rgba(255, 255, 255, 0.08);
        }
        .glass-button {
            background: linear-gradient(135deg, rgba(255, 87, 34, 0.9), rgba(230, 69, 18, 0.9));
            backdrop-filter: blur(4px);
            transition: all 0.3s ease;
        }
        .glass-button:hover {
            background: linear-gradient(135deg, rgba(255, 87, 34, 1), rgba(230, 69, 18, 1));
            box-shadow: 0 0 20px rgba(255, 87, 34, 0.4);
        }
    </style>
</head>
<body class="bg-gradient-to-br from-slate-950 via-slate-900 to-slate-950 text-slate-100 min-h-screen flex items-center justify-center p-6 selection:bg-orange-500 selection:text-white">

    <div class="fixed top-0 left-1/4 w-96 h-96 bg-orange-600/10 rounded-full blur-3xl pointer-events-none"></div>
    <div class="fixed bottom-0 right-1/4 w-96 h-96 bg-amber-600/10 rounded-full blur-3xl pointer-events-none"></div>

    <div class="glass-panel p-8 md:p-10 rounded-3xl shadow-2xl w-full max-w-md relative z-10 border border-orange-500/10">
        <div class="text-center mb-8">
            <div class="flex justify-center mb-6">
                <div class="w-14 h-14 rounded-2xl glass-button flex items-center justify-center font-bold text-2xl text-white shadow-lg">
                    P
                </div>
            </div>
            <h1 class="text-3xl font-black tracking-tight text-white mb-2">Admin Portal</h1>
            <p class="text-slate-400 text-sm">Authorize session via Secure Handshake</p>
        </div>

        @if(session('error'))
            <div class="bg-red-500/10 border border-red-500/20 text-red-400 px-4 py-3 rounded-xl mb-6 text-xs font-medium">
                <div class="flex items-center gap-2">
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
                    {{ session('error') }}
                </div>
            </div>
        @endif

        @if(session('success'))
            <div class="bg-orange-500/10 border border-orange-500/20 text-orange-400 px-4 py-3 rounded-xl mb-6 text-xs font-medium">
                <div class="flex items-center gap-2">
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
                    {{ session('success') }}
                </div>
            </div>
        @endif

        <form action="{{ route('admin.authenticate') }}" method="POST" class="space-y-5">
            @csrf
            <div>
                <label class="block text-[10px] font-black text-slate-500 uppercase tracking-[0.2em] mb-2 ml-1">Identity Email</label>
                <input type="email" name="email" required
                       class="w-full bg-slate-900/50 border border-slate-800 rounded-xl px-4 py-3.5 text-white placeholder-slate-700 focus:outline-none focus:ring-2 focus:ring-orange-500/20 focus:border-orange-500/50 transition text-sm"
                       placeholder="admin@patapoa.online">
            </div>

            <div>
                <label class="block text-[10px] font-black text-slate-500 uppercase tracking-[0.2em] mb-2 ml-1">Secure Key</label>
                <input type="password" name="password" required
                       class="w-full bg-slate-900/50 border border-slate-800 rounded-xl px-4 py-3.5 text-white placeholder-slate-700 focus:outline-none focus:ring-2 focus:ring-orange-500/20 focus:border-orange-500/50 transition text-sm"
                       placeholder="••••••••">
            </div>

            <button type="submit"
                    class="glass-button w-full text-white font-black py-4 px-4 rounded-xl shadow-lg transition duration-300 text-sm tracking-widest uppercase mt-4">
                Verify & Continue
            </button>
        </form>

        <div class="mt-10 pt-6 border-t border-slate-800/60 text-center">
            <div class="inline-flex items-center gap-2 text-[9px] text-slate-500 uppercase tracking-[0.2em] font-black">
                <span class="w-1.5 h-1.5 rounded-full bg-orange-500 animate-pulse"></span>
                Internal NACCI Systems Protocol
            </div>
        </div>
    </div>

</body>
</html>
