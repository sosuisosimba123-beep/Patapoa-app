<!DOCTYPE html>
<html lang="sw" class="dark">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="icon" type="image/x-icon" href="{{ asset('favicon.ico') }}">
    <title>Patapoa | Agiza Tukuletee</title>
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
                            card: 'rgba(30, 41, 59, 0.7)'
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
<body class="bg-gradient-to-br from-slate-950 via-slate-900 to-slate-950 text-slate-100 min-h-screen flex flex-col justify-between selection:bg-orange-500 selection:text-white">

    <div class="fixed top-0 left-1/4 w-96 h-96 bg-orange-600/10 rounded-full blur-3xl pointer-events-none"></div>
    <div class="fixed bottom-0 right-1/4 w-96 h-96 bg-amber-600/10 rounded-full blur-3xl pointer-events-none"></div>

    <header class="w-full py-6 px-6 md:px-12 flex justify-between items-center z-10">
        <div class="flex items-center space-x-3">
            <div class="w-10 h-10 rounded-xl glass-button flex items-center justify-center font-bold text-xl text-white shadow-lg">
                P
            </div>
            <span class="text-2xl font-black tracking-wider bg-gradient-to-r from-white via-slate-200 to-orange-500 bg-clip-text text-transparent">
                PATAPOA
            </span>
        </div>
        <div class="text-xs md:text-sm font-medium text-slate-400 glass-panel px-4 py-2 rounded-full">
            A product of <span class="text-orange-500 font-semibold tracking-wide">NACCI</span>
        </div>
    </header>

    <main class="flex-grow flex items-center justify-center px-6 py-12 z-10">
        <div class="max-w-4xl w-full text-center space-y-8">

            <div class="glass-panel p-8 md:p-14 rounded-3xl shadow-2xl relative overflow-hidden border border-orange-500/10">

                <div class="inline-flex items-center space-x-2 bg-orange-500/10 border border-orange-500/20 px-4 py-1.5 rounded-full text-orange-400 text-xs md:text-sm font-semibold mb-6">
                    <span class="w-2 h-2 rounded-full bg-orange-500 animate-pulse"></span>
                    <span>Agiza Tukuletee</span>
                </div>

                <h1 class="text-4xl md:text-6xl font-extrabold tracking-tight text-white mb-6 leading-tight">
                    Your Local Deliveries, <br>
                    <span class="bg-gradient-to-r from-orange-400 to-amber-500 bg-clip-text text-transparent">Faster & Smarter.</span>
                </h1>

                <p class="text-slate-300 text-base md:text-lg max-w-2xl mx-auto mb-10 leading-relaxed">
                    Connecting stores, restaurants, and independent riders across Moshi seamlessly. Fast fulfillment right to your doorstep.
                </p>

                <div class="flex flex-col sm:flex-row items-center justify-center gap-4">
                    <a href="{{ route('download.apk') }}" class="glass-button w-full sm:w-auto px-10 py-4 rounded-xl font-bold text-white shadow-lg text-center flex items-center justify-center gap-2">
                        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4"></path></svg>
                        Download App
                    </a>
                    <a href="https://wa.me/255715080235" class="w-full sm:w-auto px-10 py-4 rounded-xl font-medium text-slate-300 bg-slate-800/50 hover:bg-slate-800 border border-slate-700/50 transition text-center flex items-center justify-center gap-2">
                        <svg class="w-5 h-5 fill-current" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path d="M.057 24l1.687-6.163c-1.041-1.804-1.588-3.849-1.587-5.946.003-6.556 5.338-11.891 11.893-11.891 3.181.001 6.167 1.24 8.413 3.488 2.245 2.248 3.481 5.236 3.48 8.414-.003 6.557-5.338 11.892-11.893 11.892-1.99-.001-3.951-.5-5.688-1.448l-6.305 1.654zm6.597-3.807c1.676.995 3.276 1.591 5.392 1.592 5.448 0 9.886-4.434 9.889-9.885.002-5.462-4.415-9.89-9.881-9.892-5.452 0-9.887 4.434-9.889 9.884-.001 2.225.651 3.891 1.746 5.634l-.999 3.648 3.742-.981zm11.387-5.464c-.074-.124-.272-.198-.57-.347-.297-.149-1.758-.868-2.031-.967-.272-.099-.47-.149-.669.149-.198.297-.768.967-.941 1.165-.173.198-.347.223-.644.074-.297-.149-1.255-.462-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.297-.347.446-.521.151-.172.2-.296.3-.495.099-.198.05-.372-.025-.521-.075-.148-.669-1.611-.916-2.206-.242-.579-.487-.501-.669-.51l-.57-.01c-.198 0-.52.074-.792.372s-1.04 1.016-1.04 2.479 1.065 2.876 1.213 3.074c.149.198 2.095 3.2 5.076 4.487.709.306 1.263.489 1.694.626.712.226 1.36.194 1.872.118.571-.085 1.758-.719 2.006-1.413.248-.695.248-1.29.173-1.414z"></path></svg>
                        WhatsApp Support
                    </a>
                </div>

            </div>

            <div class="grid grid-cols-1 md:grid-cols-3 gap-4 text-left">
                <div class="glass-panel p-6 rounded-2xl">
                    <div class="text-orange-500 font-bold text-lg mb-1">⚡ Instant Dispatch</div>
                    <p class="text-slate-400 text-sm">Automated app alerts ensure zero downtime for your local orders.</p>
                </div>
                <div class="glass-panel p-6 rounded-2xl">
                    <div class="text-orange-500 font-bold text-lg mb-1">📍 Local Focus</div>
                    <p class="text-slate-400 text-sm">Built specifically for high-efficiency navigation in the Moshi area.</p>
                </div>
                <div class="glass-panel p-6 rounded-2xl">
                    <div class="text-orange-500 font-bold text-lg mb-1">🔒 Secure Core</div>
                    <p class="text-slate-400 text-sm">Powered by robust architecture ensuring safe transactions every time.</p>
                </div>
            </div>

        </div>
    </main>

    <footer class="w-full py-10 px-6 md:px-12 border-t border-slate-800/60 flex flex-col md:flex-row justify-between items-center text-sm text-slate-400 gap-6 z-10">
        <div class="max-w-3xl text-center md:text-left">
            <span>&copy; {{ date('Y') }} Patapoa. Powered by <strong class="text-slate-200">NACCI SOFTLABS</strong> — A prestigious Tanzanian technology startup by visionary entrepreneurs <span class="text-white font-bold">Eutychus Daudi Massambu</span> and <span class="text-white font-bold">Eustace Daudi Massambu</span>. Built on a foundation of world-class ambition and a commitment to pioneering high-impact digital ecosystems.</span>
        </div>
        <div class="flex items-center space-x-6">
            <span>Inquiries & Support:</span>
            <a href="tel:+255715080235" class="text-orange-400 font-semibold hover:underline flex items-center gap-1.5 whitespace-nowrap">
                📞 +255 715 080 235
            </a>
        </div>
    </footer>

</body>
</html>
