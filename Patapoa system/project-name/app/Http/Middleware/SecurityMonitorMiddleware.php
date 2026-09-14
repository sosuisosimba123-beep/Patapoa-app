<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use App\Models\SecurityAlert;
use Symfony\Component\HttpFoundation\Response;

class SecurityMonitorMiddleware
{
    public function handle(Request $request, Closure $next): Response
    {
        $response = $next($request);

        // Detect "poking" - 404s on admin routes
        if ($response->getStatusCode() === 404 && $request->is('admin/*')) {
            $this->logAlert(
                'critical',
                'Someone is poking at the admin pages',
                'An attacker is trying lots of hidden web addresses on the site, hunting for a way in.',
                $request->ip()
            );
        }

        // Detect unauthorized access to sensitive routes
        if ($response->getStatusCode() === 403) {
            $this->logAlert(
                'warning',
                'Unauthorized access attempt',
                'A user tried to access a restricted resource: ' . $request->path(),
                $request->ip()
            );
        }

        return $response;
    }

    private function logAlert($type, $title, $description, $ip)
    {
        // Avoid duplicate alerts from same IP for the same thing in the last hour
        $exists = SecurityAlert::where('source_ip', $ip)
            ->where('title', $title)
            ->where('created_at', '>=', now()->subHour())
            ->exists();

        if (!$exists) {
            SecurityAlert::create([
                'type' => $type,
                'title' => $title,
                'description' => $description,
                'source_ip' => $ip,
                'status' => 'active'
            ]);
        }
    }
}
