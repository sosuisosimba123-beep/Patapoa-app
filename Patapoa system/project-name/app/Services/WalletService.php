<?php

namespace App\Services;

use App\Models\User;
use App\Models\Wallet;
use App\Models\Transaction;
use App\Models\Order;
use Illuminate\Support\Facades\DB;

class WalletService
{
    /**
     * Move funds into Escrow (Pending Balance) after successful payment.
     *
     * @param Order $order
     * @return void
     */
    public function holdFundsInEscrow(Order $order): void
    {
        DB::transaction(function () use ($order) {
            $merchantShare = (float) $order->subtotal * 0.95;

            // Get the merchant from the order items
            $merchantItem = $order->orderItems()->first();
            if (!$merchantItem || !$merchantItem->merchant) {
                throw new \Exception("Order has no associated merchant.");
            }

            /** @var \App\Models\Merchant $merchant */
            $merchant = $merchantItem->merchant;

            if ($merchant && $merchant->user->wallet) {
                $merchant->user->wallet->increment('pending_balance', $merchantShare);

                Transaction::create([
                    'user_id' => $merchant->user_id,
                    'order_id' => $order->id,
                    'type' => 'earning',
                    'status' => 'pending',
                    'amount' => $merchantShare,
                    'currency' => 'TZS',
                    'description' => "Pending earning for Order #{$order->id} (less 5% commission)",
                ]);
            }
        });
    }

    /**
     * Release funds from escrow to available balance after delivery.
     *
     * @param Order $order
     * @return void
     */
    public function finalizeEarnings(Order $order): void
    {
        DB::transaction(function () use ($order) {
            // 1. Merchant Share Release
            $merchantItem = $order->orderItems()->first();
            if ($merchantItem && $merchantItem->merchant) {
                /** @var User $merchantUser */
                $merchantUser = $merchantItem->merchant->user;
                $merchantWallet = $merchantUser->wallet;
                $share = (float) $order->subtotal * 0.95;

                if ($merchantWallet) {
                    $merchantWallet->decrement('pending_balance', $share);
                    $merchantWallet->increment('balance', $share);

                    Transaction::where('user_id', $merchantUser->id)
                        ->where('order_id', $order->id)
                        ->update(['status' => 'completed', 'processed_at' => now()]);
                }
            }

            // 2. Rider Share (Credited directly on delivery)
            if ($order->delivery_partner_id && $order->deliveryPartner && $order->deliveryPartner->user) {
                $riderShare = (float) $order->delivery_fee * 0.95;
                $order->deliveryPartner->user->wallet->increment('balance', $riderShare);

                Transaction::create([
                    'user_id' => $order->deliveryPartner->user_id,
                    'order_id' => $order->id,
                    'type' => 'earning',
                    'status' => 'completed',
                    'amount' => $riderShare,
                    'currency' => 'TZS',
                    'description' => "Trip earning for Order #{$order->id} (less 5% commission)",
                    'processed_at' => now(),
                ]);
            }
        });
    }
}
