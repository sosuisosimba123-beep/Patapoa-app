<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class SmsService
{
    /**
     * Send an SMS message using the configured gateway.
     *
     * @param string $phone
     * @param string $message
     * @return bool
     */
    public function sendSms(string $phone, string $message): bool
    {
        $baseUrl = config('services.sms.url', 'https://api.sms-gate.app');
        $username = config('services.sms.user');
        $password = config('services.sms.pass');
        $deviceId = config('services.sms.device_id');

        try {
            $response = Http::withBasicAuth($username, $password)
                ->post("{$baseUrl}/v1/messages", [
                    'deviceId' => $deviceId,
                    'message' => [
                        'phone' => $phone,
                        'text' => $message,
                    ],
                ]);

            if ($response->successful()) {
                return true;
            }

            Log::error("SMS Gateway Error: " . $response->body());
            return false;
        } catch (\Exception $e) {
            Log::error("SMS Exception: " . $e->getMessage());
            return false;
        }
    }
}
