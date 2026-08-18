<?php
require 'vendor/autoload.php';
$app = require_once 'bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use App\Services\ClickPesaService;
use Illuminate\Support\Facades\Http;

$service = app(ClickPesaService::class);
$phone = '255622606497';

echo "--- DIAGNOSTIC START ---\n";

try {
    echo "1. Getting Token...\n";
    $token = $service->getAccessToken();
    echo "Token acquired.\n";

    echo "2. Testing Account Access (Wallet Balance)...\n";
    $balRes = Http::withToken($token)->get("https://api.clickpesa.com/v1/wallet/balance");
    echo "Balance Response: " . $balRes->status() . " - " . $balRes->body() . "\n";

    echo "3. Testing USSD Push...\n";
    $response = $service->initiateUSSD([
        'phone' => $phone,
        'amount' => 500,
        'reference' => 'PAT-TEST-' . time(),
    ]);
    print_r($response);

} catch (\Exception $e) {
    echo "ERROR: " . $e->getMessage() . "\n";
}
echo "--- DIAGNOSTIC END ---\n";
