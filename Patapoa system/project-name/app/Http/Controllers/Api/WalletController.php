<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Wallet;
use Illuminate\Http\Request;

class WalletController extends Controller
{
    public function show(Request $request)
    {
        $wallet = $request->user()->wallet;

        if (!$wallet) {
            $walletType = match($request->user()->user_type) {
                'merchant' => 'merchant',
                'rider' => 'rider',
                default => 'customer',
            };

            $wallet = Wallet::create([
                'user_id' => $request->user()->id,
                'wallet_type' => $walletType,
                'balance' => 0,
                'pending_balance' => 0,
                'currency' => 'TZS',
            ]);
        }

        return $this->successResponse($wallet, 'Wallet retrieved successfully');
    }
}
