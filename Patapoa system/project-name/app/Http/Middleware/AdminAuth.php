<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class AdminAuth
{
    /**
     * Handle an incoming request.
     *
     * @param  \Closure(\Illuminate\Http\Request): (\Symfony\Component\HttpFoundation\Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        // Check if the admin session flag exists
        if (!session()->has('patapoa_admin_authenticated')) {
            return redirect()->route('admin.login')->with('error', 'Unauthorized. Please complete login verification.');
        }

        return $next($request);
    }
}
