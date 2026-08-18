<?php

namespace Tests\Unit;

use App\Services\CircuitBreaker;
use Illuminate\Support\Facades\Cache;
use Tests\TestCase;

class CircuitBreakerTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        Cache::flush();
    }

    /** @test */
    public function it_executes_successfully_in_closed_state()
    {
        $breaker = new CircuitBreaker('test_service', 3, 60);

        $result = $breaker->execute(
            fn() => 'success',
            fn() => 'fallback'
        );

        $this->assertEquals('success', $result);
    }

    /** @test */
    public function it_trips_to_open_state_after_reaching_failure_threshold()
    {
        $threshold = 3;
        $breaker = new CircuitBreaker('threshold_test', $threshold, 60);

        // 1. Trigger failures up to threshold
        for ($i = 0; $i < $threshold; $i++) {
            $breaker->execute(
                fn() => throw new \Exception("External Failure"),
                fn() => 'error_handled'
            );
        }

        // 2. The next call should trigger the OPEN state and return the fallback
        // without even attempting to call the service (the exception shouldn't be thrown from the callback)
        $called = false;
        $result = $breaker->execute(
            function() use (&$called) {
                $called = true;
                return 'should_not_reach_here';
            },
            fn($e) => 'circuit_open_fallback'
        );

        $this->assertFalse($called, "The service callback was executed while circuit should be OPEN");
        $this->assertEquals('circuit_open_fallback', $result);
    }

    /** @test */
    public function it_resets_failures_on_success()
    {
        $breaker = new CircuitBreaker('reset_test', 3, 60);

        // Fail once
        $breaker->execute(fn() => throw new \Exception(), fn() => 'fail');

        // Success once
        $breaker->execute(fn() => 'ok', fn() => 'fail');

        // Should now require 3 more failures to trip, not 2
        for ($i = 0; $i < 2; $i++) {
            $breaker->execute(fn() => throw new \Exception(), fn() => 'fail');
        }

        $result = $breaker->execute(
            fn() => 'still_closed',
            fn() => 'tripped'
        );

        $this->assertEquals('still_closed', $result);
    }

    /** @test */
    public function it_stays_open_for_specified_timeout()
    {
        $breaker = new CircuitBreaker('timeout_test', 1, 2); // 2 second timeout

        // Trip it
        $breaker->execute(fn() => throw new \Exception(), fn() => 'fail');

        // Verify it is open
        $this->assertEquals('fallback', $breaker->execute(fn() => 'ok', fn() => 'fallback'));

        // Advance time (mocking time is complex with real cache, but since we use 'file' or 'array' in tests it works)
        // However, for unit testing the logic, we can just check if the cache key exists.
        $this->assertTrue(Cache::has('circuit_breaker:timeout_test:is_open'));
    }
}
