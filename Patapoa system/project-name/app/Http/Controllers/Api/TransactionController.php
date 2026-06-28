<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\Transaction;
use App\Models\Wallet;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;

class TransactionController extends Controller
{
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
            'payment_method' => 'required|in:mpesa,tigo_pesa,wallet',
        ]);

        if ($validator->fails()) {
            return $this->errorResponse('Validation failed', 422, $validator->errors()->toArray());
        }

        $order = Order::findOrFail($request->order_id);

        if ($order->customer_id !== $request->user()->id) {
            return $this->errorResponse('Unauthorized', 403);
        }

        if ($order->payment_status === 'paid') {
            return $this->errorResponse('Order already paid', 422);
        }

        try {
            DB::beginTransaction();

            if ($request->payment_method === 'wallet') {
                $wallet = $request->user()->wallet;

                if (!$wallet || $wallet->balance < $order->total) {
                    DB::rollBack();
                    return $this->errorResponse('Insufficient wallet balance', 422);
                }

                $wallet->decrement('balance', $order->total);

                $transaction = Transaction::create([
                    'user_id' => $request->user()->id,
                    'order_id' => $order->id,
                    'type' => 'payment',
                    'status' => 'completed',
                    'amount' => $order->total,
                    'currency' => 'TZS',
                    'payment_method' => 'wallet',
                    'description' => 'Payment for order #' . $order->id,
                    'processed_at' => now(),
                ]);

                $order->update([
                    'payment_status' => 'paid',
                    'payment_reference' => $transaction->id,
                    'status' => 'confirmed',
                ]);

            } else {
                // M-Pesa or Tigo Pesa STK Push
                // TODO: Integrate with M-Pesa/Tigo Pesa APIs
                $transaction = Transaction::create([
                    'user_id' => $request->user()->id,
                    'order_id' => $order->id,
                    'type' => 'payment',
                    'status' => 'pending',
                    'amount' => $order->total,
                    'currency' => 'TZS',
                    'payment_method' => $request->payment_method,
                    'description' => 'Payment for order #' . $order->id,
                    'transaction_reference' => 'MPESA_' . time(),
                ]);

                // Simulate STK Push
                return $this->successResponse([
                    'transaction_id' => $transaction->id,
                    'phone' => $request->user()->phone,
                    'amount' => $order->total,
                ], 'STK Push initiated. Please complete payment on your phone.');
            }

            DB::commit();

            return $this->successResponse([
                'transaction' => $transaction,
                'order' => $order->fresh(),
            ], 'Payment processed successfully');

        } catch (\Exception $e) {
            DB::rollBack();
            return $this->errorResponse('Payment failed', 500);
        }
    }

    public function paymentCallback(Request $request)
    {
        // M-Pesa/Tigo Pesa callback endpoint
        // TODO: Validate callback signature
        // TODO: Process payment confirmation

        $validator = Validator::make($request->all(), [
            'transaction_reference' => 'required|string',
            'status' => 'required|in:success,failed',
            'amount' => 'required|numeric',
        ]);

        if ($validator->fails()) {
            return $this->errorResponse('Validation failed', 422, $validator->errors()->toArray());
        }

        $transaction = Transaction::where('transaction_reference', $request->transaction_reference)
            ->first();

        if (!$transaction) {
            return $this->errorResponse('Transaction not found', 404);
        }

        try {
            DB::beginTransaction();

            if ($request->status === 'success') {
                $transaction->update([
                    'status' => 'completed',
                    'processed_at' => now(),
                ]);

                $order = $transaction->order;
                $order->update([
                    'payment_status' => 'paid',
                    'status' => 'confirmed',
                ]);

            } else {
                $transaction->update([
                    'status' => 'failed',
                    'processed_at' => now(),
                ]);

                $transaction->order->update(['payment_status' => 'failed']);
            }

            DB::commit();

            return $this->successResponse(null, 'Callback processed successfully');

        } catch (\Exception $e) {
            DB::rollBack();
            return $this->errorResponse('Callback processing failed', 500);
        }
    }
}
