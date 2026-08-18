<?php

namespace App\Services;

use App\Models\User;
use App\Models\Notification;
use App\Jobs\SendPushNotification;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Cache;
use Google\Auth\Credentials\ServiceAccountCredentials;
use Google\Auth\HttpHandler\HttpHandlerFactory;

class PushNotificationService
{
    protected $credentialsPath;
    protected $projectId;

    public function __construct()
    {
        $this->credentialsPath = config('services.firebase.credentials');
        $this->projectId = config('services.fcm.project_id');
    }

    /**
     * Get OAuth2 Access Token using Service Account
     */
    protected function getAccessToken()
    {
        return Cache::remember('fcm_v1_token', 50 * 60, function () {
            if (!file_exists($this->credentialsPath)) {
                Log::error('Firebase credentials file not found at: ' . $this->credentialsPath);
                return null;
            }

            $scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
            $credentials = new ServiceAccountCredentials($scopes, $this->credentialsPath);
            $token = $credentials->fetchAuthToken(HttpHandlerFactory::build());

            return $token['access_token'] ?? null;
        });
    }

    /**
     * Send a notification to a specific user
     */
    public function sendToUser(User $user, string $title, string $body, array $data = [])
    {
        // 1. Save to database
        Notification::create([
            'user_id' => $user->id,
            'title' => $title,
            'body' => $body,
            'data' => $data,
            'type' => $data['type'] ?? 'general',
            'is_read' => false,
        ]);

        // 2. Send via FCM if token exists
        if ($user->fcm_token) {
            return $this->sendFCM($user->fcm_token, $title, $body, $data);
        }

        return false;
    }

    /**
     * Send a notification to a topic
     */
    public function sendToTopic(string $topic, string $title, string $body, array $data = [])
    {
        return $this->sendFCM(null, $title, $body, $data, $topic);
    }

    /**
     * FCM HTTP v1 Sender
     */
    protected function sendFCM(?string $token, string $title, string $body, array $data = [], ?string $topic = null)
    {
        $accessToken = $this->getAccessToken();
        if (!$accessToken) return false;

        $project = $this->projectId;
        if (!$project) {
            // Try to extract project ID from JSON if not in config
            if (file_exists($this->credentialsPath)) {
                $json = json_decode(file_get_contents($this->credentialsPath), true);
                $project = $json['project_id'] ?? null;
            }
        }

        if (!$project) {
            Log::error('FCM Project ID not configured.');
            return false;
        }

        $url = "https://fcm.googleapis.com/v1/projects/{$project}/messages:send";

        $message = [
            'notification' => [
                'title' => $title,
                'body' => $body,
            ],
            'data' => array_map('strval', $data), // FCM v1 requires string values in data
        ];

        if ($topic) {
            $message['topic'] = $topic;
        } else {
            $message['token'] = $token;
        }

        $payload = ['message' => $message];

        // Dispatch to background queue to prevent blocking main thread
        SendPushNotification::dispatch($url, $payload, $accessToken);

        return true;
    }
}
