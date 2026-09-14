<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Third Party Services
    |--------------------------------------------------------------------------
    |
    | This file is for storing the credentials for third party services such
    | as Mailgun, Postmark, AWS and more. This file provides the de facto
    | location for this type of information, allowing packages to have
    | a conventional file to locate the various service credentials.
    |
    */

    'postmark' => [
        'key' => env('POSTMARK_API_KEY'),
    ],

    'resend' => [
        'key' => env('RESEND_API_KEY'),
    ],

    'ses' => [
        'key' => env('AWS_ACCESS_KEY_ID'),
        'secret' => env('AWS_SECRET_ACCESS_KEY'),
        'region' => env('AWS_DEFAULT_REGION', 'us-east-1'),
    ],

    'slack' => [
        'notifications' => [
            'bot_user_oauth_token' => env('SLACK_BOT_USER_OAUTH_TOKEN'),
            'channel' => env('SLACK_BOT_USER_DEFAULT_CHANNEL'),
        ],
    ],

    'clickpesa' => [
        'client_id' => env('CLICKPESA_CLIENT_ID'),
        'client_secret' => env('CLICKPESA_CLIENT_SECRET'),
        'api_key' => env('CLICKPESA_API_KEY'),
        'base_url' => env('CLICKPESA_BASE_URL', 'https://api.clickpesa.com'),
        'webhook_secret' => env('CLICKPESA_WEBHOOK_SECRET'),
    ],

    'fcm' => [
        'key' => env('FCM_SERVER_KEY'), // Legacy Key (Server Key)
        'project_id' => env('FCM_PROJECT_ID'),
    ],

    'tomtom' => [
        'key' => env('TOMTOM_API_KEY'),
    ],

    'firebase' => [
        'credentials' => env('FIREBASE_CREDENTIALS'),
    ],

    'sms' => [
        'enabled' => env('ENABLE_SMS_DISPATCH', false),
        'url' => env('SMS_GATEWAY_URL', 'https://api.sms-gate.app'),
        'user' => env('SMS_GATEWAY_USER'),
        'pass' => env('SMS_GATEWAY_PASS'),
        'device_id' => env('SMS_GATEWAY_DEVICE_ID'),
    ],

];
