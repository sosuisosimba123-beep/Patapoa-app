<?php

namespace App\Http\Traits;

use Illuminate\Support\Facades\Cache;
use Illuminate\Database\Eloquent\Builder;

trait HasCache
{
    /**
     * Cache key prefix for this controller.
     */
    protected function cachePrefix(): string
    {
        return 'api_' . class_basename($this);
    }

    /**
     * Get a cached value or compute it.
     *
     * @param string $key
     * @param callable $callback
     * @param int $ttlSeconds
     * @return mixed
     */
    protected function remember(string $key, callable $callback, int $ttlSeconds = 60)
    {
        return Cache::remember($this->cachePrefix() . ':' . $key, $ttlSeconds, $callback);
    }

    /**
     * Forget a cached key.
     */
    protected function forget(string $key): void
    {
        Cache::forget($this->cachePrefix() . ':' . $key);
    }

    /**
     * Flush all cache for this controller.
     */
    protected function flushCache(): void
    {
        // Note: Laravel doesn't support prefix-based flush without tags (Redis only)
        // For file/cache, use tagged cache if available, otherwise document this limitation
    }

    /**
     * Cache and paginate a query.
     * Caches paginated results for short TTL (30s) to reduce repeated requests.
     *
     * @param Builder $query
     * @param string $cacheKey
     * @param int $ttlSeconds
     * @param int $defaultLimit
     * @param int $maxLimit
     * @return \Illuminate\Contracts\Pagination\LengthAwarePaginator
     */
    protected function cachedPaginate(
        Builder $query,
        string $cacheKey,
        int $ttlSeconds = 30,
        int $defaultLimit = 20,
        int $maxLimit = 100
    ) {
        $limit = min((int) request()->get('limit', $defaultLimit), $maxLimit);
        $page = max((int) request()->get('page', 1), 1);
        
        $fullKey = "{$cacheKey}:{$limit}:{$page}";

        return $this->remember($fullKey, function () use ($query, $limit, $page) {
            return $query->paginate($limit, ['*'], 'page', $page);
        }, $ttlSeconds);
    }

    /**
     * Cache a collection result.
     *
     * @param Builder $query
     * @param string $cacheKey
     * @param int $ttlSeconds
     * @return \Illuminate\Database\Eloquent\Collection
     */
    protected function cachedGet(Builder $query, string $cacheKey, int $ttlSeconds = 60)
    {
        return $this->remember($cacheKey, function () use ($query) {
            return $query->get();
        }, $ttlSeconds);
    }

    /**
     * Cache a single model result.
     *
     * @param Builder $query
     * @param string $cacheKey
     * @param int $ttlSeconds
     * @return \Illuminate\Database\Eloquent\Model|null
     */
    protected function cachedFirst(Builder $query, string $cacheKey, int $ttlSeconds = 60)
    {
        return $this->remember($cacheKey, function () use ($query) {
            return $query->first();
        }, $ttlSeconds);
    }
}
