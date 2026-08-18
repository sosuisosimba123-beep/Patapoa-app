<?php

namespace App\Services;

use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Log;

class CircuitBreaker
{
    protected const STATE_CLOSED = 'closed';
    protected const STATE_OPEN = 'open';
    protected const STATE_HALF_OPEN = 'half_open';

    protected string $serviceName;
    protected int $threshold;
    protected int $timeout;

    /**
     * @param string $serviceName Unique name for the external service
     * @param int $threshold Number of failures before tripping
     * @param int $timeout Seconds to stay in 'OPEN' state
     */
    public function __construct(string $serviceName, int $threshold = 5, int $timeout = 60)
    {
        $this->serviceName = $serviceName;
        $this->threshold = $threshold;
        $this->timeout = $timeout;
    }

    /**
     * Execute the external call wrapped in circuit breaker logic.
     */
    public function execute(callable $callback, callable $fallback)
    {
        $state = $this->getState();

        if ($state === self::STATE_OPEN) {
            return $fallback(new \Exception("Circuit is OPEN for service: {$this->serviceName}"));
        }

        try {
            $result = $callback();
            $this->onSuccess();
            return $result;
        } catch (\Exception $e) {
            $this->onFailure();
            return $fallback($e);
        }
    }

    protected function getState(): string
    {
        if (Cache::get($this->getOpenKey())) {
            return self::STATE_OPEN;
        }

        if ($this->getFailures() >= $this->threshold) {
            // We've reached threshold, trip the circuit
            $this->trip();
            return self::STATE_OPEN;
        }

        return self::STATE_CLOSED;
    }

    protected function trip(): void
    {
        Log::warning("Circuit Breaker TRIPPED for service: {$this->serviceName}");
        Cache::put($this->getOpenKey(), true, $this->timeout);
    }

    protected function onSuccess(): void
    {
        Cache::forget($this->getFailuresKey());
        Cache::forget($this->getOpenKey());
    }

    protected function onFailure(): void
    {
        $failures = $this->getFailures() + 1;
        Cache::put($this->getFailuresKey(), $failures, $this->timeout * 2);

        Log::error("Circuit Breaker FAILURE noted for {$this->serviceName}. Count: {$failures}");
    }

    protected function getFailures(): int
    {
        return (int) Cache::get($this->getFailuresKey(), 0);
    }

    protected function getFailuresKey(): string
    {
        return "circuit_breaker:{$this->serviceName}:failures";
    }

    protected function getOpenKey(): string
    {
        return "circuit_breaker:{$this->serviceName}:is_open";
    }
}
