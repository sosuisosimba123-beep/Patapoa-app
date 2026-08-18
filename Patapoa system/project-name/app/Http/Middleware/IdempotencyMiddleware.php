<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Symfony\Component\HttpFoundation\Response;

class IdempotencyMiddleware
{
    /**
     * Handle an incoming request.
     *
     * @param  \Closure(\Illuminate\Http\Request): (\Symfony\Component\HttpFoundation\Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        // Only apply to POST and PUT requests
        if (!$request->isMethod('POST') && !$request->isMethod('PUT')) {
            return $next($request);
        }

        $idempotencyKey = $request->header('X-Idempotency-Key');

        // If no idempotency key is provided, just proceed
        if (!$idempotencyKey) {
            return $next($request);
        }

        // Create a unique cache key based on the idempotency key and user ID (if available)
        // to prevent cross-user key collisions.
        $userId = $request->user()?->id ?? 'guest';
        $cacheKey = "idempotency:{$userId}:{$idempotencyKey}";

        // 1. Check if we have a cached response for this key
        $cachedResponse = Cache::get($cacheKey);

        if ($cachedResponse) {
            return response()->json(
                $cachedResponse['content'],
                $cachedResponse['status'],
                array_merge($cachedResponse['headers'], ['X-Idempotency-Cache' => 'HIT'])
            );
        }

        // 2. Proceed with the request
        $response = $next($request);

        // 3. Cache the response if it's a successful mutation (200-299) or specific error types if desired
        // We typically only cache successful mutations to allow retries on transient errors.
        if ($response->getStatusCode() >= 200 && $response->getStatusCode() < 300) {
            $content = json_decode($response->getContent(), true);

            // If the content is not valid JSON, we might not want to cache it in this simple middleware
            if (json_last_error() === JSON_ERROR_NONE) {
                Cache::put($cacheKey, [
                    'content' => $content,
                    'status' => $response->getStatusCode(),
                    'headers' => $response->headers->all(),
                ], now()->addHours(24));
            }
        }

        return $response;
    }
}
