<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\Transaction;
use App\Models\Wallet;
use App\Services\ClickPesaService;
use App\Services\WalletService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Log;
use App\Services\PushNotificationService;

class TransactionController extends Controller
{
    protected $clickpesa;
    protected $notifications;
    protected $walletService;

    public function __construct(
        ClickPesaService $clickpesa,
        PushNotificationService $notifications,
        WalletService $walletService
    ) {
        $this->clickpesa = $clickpesa;
        $this->notifications = $notifications;
        $this->walletService = $walletService;
    }

    public function index(Request $request)
    {
        $query = $request->user()->transactions()
            ->with('order')
            ->orderBy('created_at', 'desc');

        $transactions = $this->paginateQuery($query, $request, 20, 100);
        return $this->paginatedResponse($transactions, 'Transactions retrieved successfully');
    }

    public function initiatePayment(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'order_id' => 'required|exists:orders,id',
            'payment_method' => 'required|in:mpesa,tigo_pesa,airtel_money,halopesa,card,wallet',
        ]);

        if ($validator->fails()) {
            return $this->errorResponse('Validation failed', 422, $validator->errors()->toArray());
        }

        $orderId = $request->input('order_id');
        $order = Order::findOrFail($orderId);
        if ($order->customer_id !== $request->user()->id) return $this->errorResponse('Unauthorized', 403);
        if ($order->payment_status === 'paid') return $this->errorResponse('Order already paid', 422);

        $paymentMethod = $request->input('payment_method');

        try {
            DB::beginTransaction();

            if ($paymentMethod === 'wallet') {
                return $this->processWalletPayment($request->user(), $order);
            } else {
                $transRef = 'PAT-PAY-' . time() . '-' . $order->id;

                $transaction = Transaction::create([
                    'user_id' => $request->user()->id,
                    'order_id' => $order->id,
                    'type' => 'payment',
                    'status' => 'pending',
                    'amount' => $order->total,
                    'currency' => 'TZS',
                    'payment_method' => $paymentMethod,
                    'description' => 'Payment for order #' . $order->id,
                    'transaction_reference' => $transRef,
                ]);

                if ($paymentMethod === 'card') {
                    $response = $this->clickpesa->initiateCardPayment([
                        'amount' => $order->total,
                        'reference' => $transRef,
                        'name' => $request->user()->name,
                        'email' => $request->user()->email,
                    ]);
                } else {
                    $response = $this->clickpesa->initiateUSSD([
                        'amount' => $order->total,
                        'reference' => $transRef,
                        'phone' => $request->user()->phone,
                    ]);
                }

                DB::commit();

                return $this->successResponse([
                    'transaction' => $transaction,
                    'instruction' => 'Follow the prompt on your phone.',
                    'payment_url' => $response['checkout_url'] ?? null,
                ], 'Payment initiated via Clickpesa');
            }

        } catch (\Exception $e) {
            DB::rollBack();
            Log::error('Payment Initiation Error', ['error' => $e->getMessage()]);
            return $this->errorResponse('Failed to create payment: ' . $e->getMessage(), 500);
        }
    }

    protected function processWalletPayment($user, $order)
    {
        $wallet = $user->wallet;
        if (!$wallet || $wallet->balance < $order->total) {
            DB::rollBack();
            return $this->errorResponse('Insufficient wallet balance', 422);
        }

        $wallet->decrement('balance', $order->total);

        $transaction = Transaction::create([
            'user_id' => $user->id,
            'order_id' => $order->id,
            'type' => 'payment',
            'status' => 'completed',
            'amount' => $order->total,
            'currency' => 'TZS',
            'payment_method' => 'wallet',
            'description' => 'Wallet payment for order #' . $order->id,
            'processed_at' => now(),
        ]);

        $order->update([
            'payment_status' => 'paid',
            'payment_reference' => $transaction->id,
            'status' => 'paid_securely',
        ]);

        $this->dispatchOrderToWorkflows($order);

        DB::commit();

        return $this->successResponse([
            'transaction' => $transaction,
            'order' => $order->fresh(),
        ], 'Payment processed successfully and order dispatched.');
    }

    public function checkStatus(Request $request, $orderId)
    {
        $order = Order::findOrFail($orderId);
        if ($order->customer_id !== $request->user()->id) return $this->errorResponse('Unauthorized', 403);

        if ($order->payment_status === 'pending') {
            $transaction = Transaction::where('order_id', $order->id)
                ->where('status', 'pending')
                ->latest()
                ->first();

            if ($transaction && $transaction->transaction_reference) {
                try {
                    $statusData = $this->clickpesa->queryStatus($transaction->transaction_reference);

                    if ($statusData['status'] === 'SUCCESS') {
                        DB::transaction(function() use ($transaction, $order) {
                            $transaction->update(['status' => 'completed', 'processed_at' => now()]);
                            $order->update(['payment_status' => 'paid', 'status' => 'paid_securely']);
                            $this->dispatchOrderToWorkflows($order);
                        });
                        return $this->successResponse(['order_id' => $order->id, 'payment_status' => 'paid'], 'Payment confirmed');
                    }
                } catch (\Exception $e) {
                    Log::error('Status Sync Failed', ['error' => $e->getMessage()]);
                }
            }
        }

        return $this->successResponse(['order_id' => $order->id, 'payment_status' => $order->payment_status], 'Status retrieved');
    }

    protected function dispatchOrderToWorkflows($order)
    {
        try {
            // 1. Hold funds in Escrow
            $this->walletService->holdFundsInEscrow($order);

            // 2. Notify Customer
            $this->notifications->sendToUser(
                $order->customer,
                'Payment Successful',
                'Your payment for order #' . $order->id . ' was successful. The merchant is now preparing your items.',
                ['type' => 'payment_success', 'order_id' => (string)$order->id]
            );

            // 3. Notify Merchant
            $merchantItem = $order->orderItems()->first();
            if ($merchantItem && $merchantItem->merchant && $merchantItem->merchant->user) {
                $this->notifications->sendToUser(
                    $merchantItem->merchant->user,
                    'New Paid Order #' . $order->id,
                    'You have a new paid order. Please start preparation.',
                    ['type' => 'new_order', 'order_id' => (string)$order->id]
                );
            }

            // 4. Notify Delivery Partners
            $this->notifications->sendToTopic(
                'riders',
                'Delivery Task Available',
                'A new paid order #' . $order->id . ' is being prepared.',
                ['type' => 'new_delivery', 'order_id' => (string)$order->id]
            );
        } catch (\Exception $e) {
            Log::error('Order Workflow Dispatch Failed', ['order_id' => $order->id, 'error' => $e->getMessage()]);
        }
    }

    public function payoutRequest(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'amount' => 'required|numeric|min:5000',
            'phone' => 'required|string',
            'provider' => 'required|in:mpesa,tigo_pesa,airtel_money,halopesa',
        ]);

        if ($validator->fails()) return $this->errorResponse('Validation failed', 422, $validator->errors()->toArray());

        $user = $request->user();
        $wallet = $user->wallet;

        $amount = $request->input('amount');
        if (!$wallet || $wallet->balance < $amount) {
            return $this->errorResponse('Insufficient balance. Available: TZS ' . number_format($wallet->balance ?? 0), 422);
        }

        try {
            DB::beginTransaction();

            $transRef = 'PO-' . strtoupper($user->user_type[0]) . '-' . time() . '-' . $user->id;
            $wallet->decrement('balance', $amount);

            $provider = $request->input('provider');
            $phone = $request->input('phone');

            $transaction = Transaction::create([
                'user_id' => $user->id,
                'type' => 'payout',
                'status' => 'pending',
                'amount' => $amount,
                'currency' => 'TZS',
                'payment_method' => $provider,
                'description' => 'Payout to ' . $phone,
                'transaction_reference' => $transRef,
            ]);

            $this->clickpesa->payout([
                'amount' => $amount,
                'phone' => $phone,
                'reference' => $transRef,
                'provider' => $provider,
            ]);

            DB::commit();

            return $this->successResponse(['transaction' => $transaction], 'Payout request submitted.');
        } catch (\Exception $e) {
            DB::rollBack();
            Log::error('Payout Failed', ['error' => $e->getMessage()]);
            return $this->errorResponse('Payout automation failed: ' . $e->getMessage(), 500);
        }
    }

    /**
     * ClickPesa Webhook Callback
     */
    public function paymentCallback(Request $request)
    {
        Log::info('ClickPesa Webhook Received', ['payload' => $request->all()]);

        if (!$this->clickpesa->verifyWebhookSignature($request)) {
            Log::warning('ClickPesa Webhook Signature Verification Failed');
            return response()->json(['message' => 'Invalid signature'], 403);
        }

        $payload = $request->all();
        $reference = $payload['reference'] ?? $payload['orderReference'] ?? null;
        $status = strtoupper($payload['status'] ?? '');

        if (!$reference) return response()->json(['message' => 'Missing reference'], 400);

        $transaction = Transaction::where('transaction_reference', $reference)->first();

        if (!$transaction) {
            Log::error('Transaction not found for reference: ' . $reference);
            return response()->json(['message' => 'Transaction not found'], 404);
        }

        if ($transaction->status === 'completed') {
            return response()->json(['message' => 'Already processed']);
        }

        try {
            DB::transaction(function() use ($transaction, $status, $payload) {
                if (in_array($status, ['SUCCESSFUL', 'PAID', 'COMPLETED'])) {
                    $transaction->update(['status' => 'completed', 'processed_at' => now()]);

                    if ($transaction->type === 'payment' && $transaction->order) {
                        $order = $transaction->order;
                        $order->update(['payment_status' => 'paid', 'status' => 'paid_securely']);
                        $this->dispatchOrderToWorkflows($order);
                    }

                    // Note: If type is 'payout', we already decremented balance, just mark as completed.
                } elseif (in_array($status, ['FAILED', 'CANCELLED', 'DECLINED'])) {
                    $transaction->update(['status' => 'failed']);

                    // Reverse balance if payout failed
                    if ($transaction->type === 'payout') {
                        $wallet = $transaction->user->wallet;
                        if ($wallet) $wallet->increment('balance', $transaction->amount);
                    }
                }
            });

            return response()->json(['message' => 'Webhook processed']);
        } catch (\Exception $e) {
            Log::error('Webhook Processing Error', ['error' => $e->getMessage()]);
            return response()->json(['message' => 'Processing error'], 500);
        }
    }
}
