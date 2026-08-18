<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Cache;
use App\Models\ClickpesaPayment;
use Illuminate\Http\Request;

class ClickPesaService
{
    protected $clientId;
    protected $apiKey;
    protected $baseUrl;
    protected $breaker;

    public function __construct()
    {
        $this->clientId = config('services.clickpesa.client_id');
        $this->apiKey = config('services.clickpesa.api_key');
        $this->baseUrl = rtrim(config('services.clickpesa.base_url'), '/');

        // Threshold: 5 failures, Timeout: 60s
        $this->breaker = new CircuitBreaker('clickpesa', 5, 60);
    }

    /**
     * Generate Access Token
     */
    public function getAccessToken()
    {
        return $this->breaker->execute(function () {
            return Cache::remember('clickpesa_oauth_token', 55 * 60, function () {
                $url = "{$this->baseUrl}/third-parties/generate-token";

                $response = Http::withHeaders([
                    'client-id' => $this->clientId,
                    'api-key' => $this->apiKey,
                    'Content-Type' => 'application/json',
                ])->post($url);

                if ($response->failed()) {
                    Log::error('Clickpesa Token Generation Failed', [
                        'status' => $response->status(),
                        'body' => $response->json(),
                    ]);
                    throw new \Exception('Unable to authenticate with ClickPesa: ' . ($response->json()['message'] ?? $response->body()));
                }

                $data = $response->json();
                $token = $data['token'] ?? $data['access_token'] ?? null;

                if (!$token) {
                    throw new \Exception('ClickPesa response missing token: ' . json_encode($data));
                }

                return $token;
            });
        }, function (\Exception $e) {
            throw $e;
        });
    }

    /**
     * Initiate USSD Checkout (Collection)
     */
    public function initiateUSSD(array $params)
    {
        return $this->breaker->execute(function () use ($params) {
            $token = $this->getAccessToken();

            $payload = [
                'amount' => (string) $params['amount'],
                'currency' => $params['currency'] ?? 'TZS',
                'phoneNumber' => $params['phone'],
                'orderReference' => (string) $params['reference'],
            ];

            $payment = ClickpesaPayment::create([
                'reference_id' => $params['reference'],
                'payment_method' => 'ussd',
                'phone_number' => $params['phone'],
                'amount' => $params['amount'],
                'currency' => $payload['currency'],
                'request_payload' => $payload,
                'status' => 'pending',
            ]);

            $url = "{$this->baseUrl}/third-parties/payments/initiate-ussd-push-request";

            $response = Http::withToken($token)
                ->withHeaders([
                    'client-id' => $this->clientId,
                    'Content-Type' => 'application/json',
                ])
                ->post($url, $payload);

            if ($response->failed()) {
                $errorMsg = $response->json()['message'] ?? $response->body();
                $payment->update(['status' => 'failed', 'status_detail' => $errorMsg]);
                throw new \Exception('ClickPesa USSD Push Failed: ' . $errorMsg);
            }

            $responseData = $response->json();

            $payment->update([
                'response_payload' => $responseData,
                'external_id' => $responseData['transaction_id'] ?? null,
                'status' => 'processing',
                'status_detail' => $responseData['message'] ?? 'Processing',
            ]);

            return [
                'success' => true,
                'transaction_id' => $responseData['transaction_id'] ?? null,
                'message' => $responseData['message'] ?? 'USSD Push Initiated',
                'raw' => $responseData
            ];
        }, function (\Exception $e) {
            return [
                'success' => false,
                'message' => 'Payment system temporarily unavailable.',
                'error' => $e->getMessage()
            ];
        });
    }

    /**
     * Payout (B2C Disbursement) to Mobile Money
     */
    public function payout(array $params)
    {
        return $this->breaker->execute(function () use ($params) {
            $token = $this->getAccessToken();

            // Map internal provider names to ClickPesa network names
            $networkMap = [
                'mpesa' => 'VODACOM',
                'tigo_pesa' => 'TIGO',
                'airtel_money' => 'AIRTEL',
                'halopesa' => 'HALOTEL',
            ];

            $network = $networkMap[strtolower($params['provider'] ?? '')] ?? 'VODACOM';

            $payload = [
                'reference' => (string) $params['reference'],
                'amount' => (string) $params['amount'],
                'currency' => $params['currency'] ?? 'TZS',
                'payout_method' => 'mobile_money',
                'customer' => [
                    'phone' => $params['phone'],
                    'network' => $network,
                ],
                'description' => $params['description'] ?? 'Patapoa Earning Payout',
            ];

            $payment = ClickpesaPayment::create([
                'reference_id' => $params['reference'],
                'payment_method' => 'payout',
                'phone_number' => $params['phone'],
                'amount' => $params['amount'],
                'status' => 'pending',
                'request_payload' => $payload,
            ]);

            $url = "{$this->baseUrl}/third-parties/payouts/create-mobile-money-payout";

            $response = Http::withToken($token)
                ->withHeaders([
                    'client-id' => $this->clientId,
                    'Content-Type' => 'application/json',
                ])
                ->post($url, $payload);

            $responseData = $response->json();

            if ($response->successful()) {
                $payment->update([
                    'response_payload' => $responseData,
                    'external_id' => $responseData['payout_id'] ?? $responseData['transaction_id'] ?? null,
                    'status' => 'processing',
                    'status_detail' => 'Payout initiated successfully',
                ]);
                return $responseData;
            } else {
                $errorMsg = $responseData['message'] ?? 'Payout initiation failed';
                $payment->update([
                    'status' => 'failed',
                    'status_detail' => $errorMsg,
                    'response_payload' => $responseData
                ]);
                throw new \Exception($errorMsg);
            }
        }, function (\Exception $e) {
            Log::error('Payout Service Error', ['error' => $e->getMessage()]);
            return [
                'success' => false,
                'message' => 'Payout automation system is currently offline.',
                'error' => $e->getMessage()
            ];
        });
    }

    /**
     * Query status
     */
    public function queryStatus(string $reference)
    {
        return $this->breaker->execute(function () use ($reference) {
            $token = $this->getAccessToken();
            $url = "{$this->baseUrl}/third-parties/payments/query-payment-status";

            $response = Http::withToken($token)
                ->get($url, ['orderReference' => $reference]);

            if ($response->failed()) return ['status' => 'ERROR'];

            $data = $response->json();
            $remoteStatus = strtoupper($data['status'] ?? 'PENDING');

            $standardStatus = 'PENDING';
            if (in_array($remoteStatus, ['SUCCESSFUL', 'PAID', 'COMPLETED'])) $standardStatus = 'SUCCESS';
            elseif (in_array($remoteStatus, ['FAILED', 'CANCELLED', 'DECLINED', 'EXPIRED'])) $standardStatus = 'FAILED';
            elseif (in_array($remoteStatus, ['PROCESSING', 'INITIATED', 'SENT'])) $standardStatus = 'PROCESSING';

            return [
                'status' => $standardStatus,
                'remote_status' => $remoteStatus,
                'transaction_id' => $data['transaction_id'] ?? null,
                'amount' => $data['amount'] ?? null,
                'raw' => $data
            ];
        });
    }

    /**
     * Verify Webhook Signature (Security)
     */
    public function verifyWebhookSignature(Request $request): bool
    {
        $signature = $request->header('X-ClickPesa-Signature');
        $secret = config('services.clickpesa.webhook_secret');

        if (!$signature || !$secret) return false;

        $computedSignature = hash_hmac('sha256', $request->getContent(), $secret);

        return hash_equals($computedSignature, $signature);
    }
}
