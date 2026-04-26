<?php

namespace App\Http\Controllers\Api\V1\Reader;

use App\Http\Controllers\Controller;
use App\Models\TopUp;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class TopUpController extends Controller
{
    /**
     * Coin packages available for purchase.
     * 1 Coin = Rp 100 (base rate)
     */
    private const PACKAGES = [
        'pkg_basic'    => ['name' => 'Basic',    'price_idr' => 10000,  'coins' => 100,  'bonus' => 0],
        'pkg_standard' => ['name' => 'Standard', 'price_idr' => 25000,  'coins' => 260,  'bonus' => 10],
        'pkg_premium'  => ['name' => 'Premium',  'price_idr' => 50000,  'coins' => 550,  'bonus' => 50],
        'pkg_whale'    => ['name' => 'Whale',    'price_idr' => 100000, 'coins' => 1150, 'bonus' => 150],
    ];

    /** GET /reader/topup/packages — List available packages */
    public function packages(): JsonResponse
    {
        $packages = collect(self::PACKAGES)->map(function ($pkg, $id) {
            return array_merge(['id' => $id], $pkg);
        })->values();

        return response()->json(['data' => $packages]);
    }

    /** GET /reader/topup/history — User's top-up history */
    public function history(Request $request): JsonResponse
    {
        $topups = TopUp::where('user_id', $request->user()->id)
            ->orderBy('created_at', 'desc')
            ->limit(50)
            ->get();

        return response()->json(['data' => $topups]);
    }

    /**
     * POST /reader/topup/create — Create a Midtrans Snap transaction.
     * Returns a snap_token that the Flutter app uses to open the payment UI.
     */
    public function create(Request $request): JsonResponse
    {
        $request->validate([
            'package_id' => 'required|string|in:pkg_basic,pkg_standard,pkg_premium,pkg_whale',
        ]);

        $package = self::PACKAGES[$request->package_id];
        $user    = $request->user();

        // Generate unique order ID
        $orderId = 'TOPUP-' . $user->id . '-' . time() . '-' . rand(100, 999);

        // Save pending TopUp record
        $topUp = TopUp::create([
            'user_id'    => $user->id,
            'order_id'   => $orderId,
            'package_id' => $request->package_id,
            'amount_idr' => $package['price_idr'],
            'coins'      => $package['coins'],
            'status'     => 'pending',
        ]);

        // Build Midtrans Snap payload
        $serverKey = config('services.midtrans.server_key');

        if (!$serverKey) {
            // Fallback: return order info without snap_token for testing
            return response()->json([
                'success'  => true,
                'order_id' => $orderId,
                'snap_token' => null,
                'message'  => 'Midtrans belum dikonfigurasi. Gunakan webhook manual untuk testing.',
                'topup'    => $topUp,
            ]);
        }

        $isProduction = config('services.midtrans.is_production', false);
        $baseUrl = $isProduction
            ? 'https://app.midtrans.com/snap/v1/transactions'
            : 'https://app.sandbox.midtrans.com/snap/v1/transactions';

        $payload = [
            'transaction_details' => [
                'order_id'     => $orderId,
                'gross_amount' => $package['price_idr'],
            ],
            'customer_details' => [
                'first_name' => $user->name,
                'email'      => $user->email,
            ],
            'enabled_payments' => ['other_qris'],  // QRIS only
            'item_details' => [[
                'id'       => $request->package_id,
                'price'    => $package['price_idr'],
                'quantity' => 1,
                'name'     => "Top-Up {$package['coins']} Coins ({$package['name']})",
            ]],
        ];

        // Call Midtrans Snap API
        $ch = curl_init($baseUrl);
        curl_setopt_array($ch, [
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_POST           => true,
            CURLOPT_POSTFIELDS     => json_encode($payload),
            CURLOPT_HTTPHEADER     => [
                'Content-Type: application/json',
                'Accept: application/json',
                'Authorization: Basic ' . base64_encode($serverKey . ':'),
            ],
        ]);

        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);

        if ($httpCode !== 201) {
            $topUp->update(['status' => 'failed']);
            return response()->json([
                'success' => false,
                'message' => 'Gagal membuat transaksi pembayaran.',
            ], 500);
        }

        $result = json_decode($response, true);

        return response()->json([
            'success'    => true,
            'order_id'   => $orderId,
            'snap_token' => $result['token'] ?? null,
            'redirect_url' => $result['redirect_url'] ?? null,
            'topup'      => $topUp,
        ]);
    }

    /**
     * POST /reader/topup/check-status — Manual status check (polling fallback).
     * Used if webhook hasn't arrived yet.
     */
    public function checkStatus(Request $request): JsonResponse
    {
        $request->validate(['order_id' => 'required|string']);

        $topUp = TopUp::where('order_id', $request->order_id)
            ->where('user_id', $request->user()->id)
            ->firstOrFail();

        // If already paid, return immediately
        if ($topUp->status === 'paid') {
            return response()->json([
                'status'      => 'paid',
                'total_coins' => $request->user()->fresh()->coins,
            ]);
        }

        // Check with Midtrans API
        $serverKey = config('services.midtrans.server_key');
        if (!$serverKey) {
            return response()->json(['status' => $topUp->status]);
        }

        $isProduction = config('services.midtrans.is_production', false);
        $baseUrl = $isProduction
            ? 'https://api.midtrans.com'
            : 'https://api.sandbox.midtrans.com';

        $ch = curl_init("{$baseUrl}/v2/{$topUp->order_id}/status");
        curl_setopt_array($ch, [
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_HTTPHEADER     => [
                'Accept: application/json',
                'Authorization: Basic ' . base64_encode($serverKey . ':'),
            ],
        ]);

        $response = curl_exec($ch);
        curl_close($ch);
        $result = json_decode($response, true);

        $transactionStatus = $result['transaction_status'] ?? '';

        if (in_array($transactionStatus, ['capture', 'settlement'])) {
            // Process payment if webhook hasn't done it
            $this->processPayment($topUp, $result);
        }

        return response()->json([
            'status'      => $topUp->fresh()->status,
            'total_coins' => $request->user()->fresh()->coins,
        ]);
    }

    /**
     * Process a successful payment — called by webhook or status check.
     */
    public static function processPayment(TopUp $topUp, array $midtransData): void
    {
        // Prevent double processing
        if ($topUp->status === 'paid') {
            return;
        }

        \Illuminate\Support\Facades\DB::transaction(function () use ($topUp, $midtransData) {
            $topUp->update([
                'status'                  => 'paid',
                'midtrans_transaction_id' => $midtransData['transaction_id'] ?? null,
                'payment_type'            => $midtransData['payment_type'] ?? 'qris',
                'paid_at'                 => now(),
            ]);

            // Lock user row and add coins
            $user = \App\Models\User::lockForUpdate()->find($topUp->user_id);
            $user->increment('coins', $topUp->coins);

            // Log transaction
            \App\Models\Transaction::create([
                'user_id'     => $user->id,
                'type'        => 'topup',
                'amount'      => $topUp->coins,
                'description' => "Top-up: {$topUp->coins} Coins (Rp " . number_format($topUp->amount_idr, 0, ',', '.') . ")",
            ]);
        });
    }
}
