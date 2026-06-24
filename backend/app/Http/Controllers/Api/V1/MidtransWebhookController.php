<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Controllers\Api\V1\Reader\TopUpController;
use App\Models\TopUp;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class MidtransWebhookController extends Controller
{
    /**
     * Handle Midtrans payment notification (Webhook).
     * This endpoint is called by Midtrans servers when payment status changes.
     * No auth required — validated via signature key.
     */
    public function handle(Request $request): JsonResponse
    {
        $data = $request->all();

        Log::info('Midtrans Webhook received', $data);

        // Server key is REQUIRED for webhook validation — reject if not configured
        $serverKey = config('services.midtrans.server_key');
        if (!$serverKey) {
            Log::error('Midtrans Webhook: Server key not configured. Rejecting request.');
            return response()->json(['message' => 'Payment gateway not configured'], 503);
        }

        // Verify signature
        $orderId       = $data['order_id'] ?? '';
        $statusCode    = $data['status_code'] ?? '';
        $grossAmount   = $data['gross_amount'] ?? '';
        $signatureKey  = $data['signature_key'] ?? '';

        $expectedSignature = hash('sha512', $orderId . $statusCode . $grossAmount . $serverKey);

        if ($signatureKey !== $expectedSignature) {
            Log::warning('Midtrans Webhook: Invalid signature', [
                'order_id' => $orderId,
                'expected' => $expectedSignature,
                'received' => $signatureKey,
            ]);
            return response()->json(['message' => 'Invalid signature'], 403);
        }

        // Find the TopUp record
        $topUp = TopUp::where('order_id', $orderId)->first();

        if (!$topUp) {
            Log::warning('Midtrans Webhook: Order not found', ['order_id' => $orderId]);
            return response()->json(['message' => 'Order not found'], 404);
        }

        // Verify gross_amount matches the expected price
        $receivedAmount = floatval($grossAmount);
        if ($receivedAmount < $topUp->amount_idr) {
            Log::warning('Midtrans Webhook: gross_amount mismatch', [
                'order_id'        => $orderId,
                'expected_amount' => $topUp->amount_idr,
                'received_amount' => $receivedAmount,
            ]);
            $topUp->update(['status' => 'failed']);
            return response()->json(['message' => 'Amount mismatch'], 400);
        }

        $transactionStatus = $data['transaction_status'] ?? '';
        $fraudStatus       = $data['fraud_status'] ?? 'accept';

        // Process based on transaction status
        if ($transactionStatus === 'capture' || $transactionStatus === 'settlement') {
            if ($fraudStatus === 'accept') {
                TopUpController::processPayment($topUp, $data);
                Log::info("Midtrans Webhook: Payment SUCCESS for {$orderId}");
            } else {
                Log::warning("Midtrans Webhook: Payment flagged as fraud for {$orderId}", [
                    'fraud_status' => $fraudStatus,
                ]);
                $topUp->update(['status' => 'failed']);
            }
        } elseif (in_array($transactionStatus, ['deny', 'cancel', 'expire'])) {
            $topUp->update(['status' => $transactionStatus === 'expire' ? 'expired' : 'failed']);
            Log::info("Midtrans Webhook: Payment {$transactionStatus} for {$orderId}");
        } elseif ($transactionStatus === 'pending') {
            Log::info("Midtrans Webhook: Payment PENDING for {$orderId}");
        }

        // Always return 200 to Midtrans
        return response()->json(['message' => 'OK']);
    }
}
