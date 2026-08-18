<?php

namespace App\Jobs;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class SendPushNotification implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    protected $payload;
    protected $url;
    protected $token;

    /**
     * Create a new job instance.
     */
    public function __construct(string $url, array $payload, string $token)
    {
        $this->url = $url;
        $this->payload = $payload;
        $this->token = $token;
    }

    /**
     * Execute the job.
     */
    public function handle(): void
    {
        try {
            $response = Http::withToken($this->token)->post($this->url, $this->payload);

            if (!$response->successful()) {
                Log::error('Queued FCM Failed', [
                    'status' => $response->status(),
                    'body' => $response->json()
                ]);
            }
        } catch (\Exception $e) {
            Log::error('Queued FCM Exception', ['error' => $e->getMessage()]);
        }
    }
}
