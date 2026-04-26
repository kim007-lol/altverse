<?php

namespace App\Http\Controllers\Api\V1\Author;

use App\Http\Controllers\Controller;
use App\Models\Transaction;
use App\Models\Withdrawal;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class WithdrawalController extends Controller
{
    /** Get author's withdrawal history */
    public function index(Request $request): JsonResponse
    {
        $withdrawals = Withdrawal::where('user_id', $request->user()->id)
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json(['data' => $withdrawals]);
    }

    /** Request a withdrawal */
    public function store(Request $request): JsonResponse
    {
        $request->validate([
            'amount_coins' => 'required|integer|min:1000',
            'bank_name' => 'required|string|max:100',
            'bank_account_number' => 'required|string|max:100',
            'bank_account_name' => 'required|string|max:100',
        ]);

        $user = $request->user();
        $amountCoins = $request->amount_coins;

        // Platform Exchange Rate: 1 Coin = Rp 70
        $exchangeRate = 70;
        $amountIdr = $amountCoins * $exchangeRate;

        try {
            DB::transaction(function () use ($user, $amountCoins, $amountIdr, $request) {
                $lockedUser = \App\Models\User::lockForUpdate()->find($user->id);

                if ($lockedUser->coins < $amountCoins) {
                    throw new \Exception('Koin tidak cukup untuk penarikan');
                }

                // Deduct coins
                $lockedUser->decrement('coins', $amountCoins);

                // Create Transaction
                Transaction::create([
                    'user_id' => $lockedUser->id,
                    'type' => 'withdrawal',
                    'amount' => -$amountCoins,
                    'description' => "Penarikan Dana: {$amountCoins} Coins (Rp " . number_format($amountIdr, 0, ',', '.') . ")",
                ]);

                // Create Withdrawal Request
                Withdrawal::create([
                    'user_id' => $lockedUser->id,
                    'amount_coins' => $amountCoins,
                    'amount_idr' => $amountIdr,
                    'status' => 'pending',
                    'bank_name' => $request->bank_name,
                    'bank_account_number' => $request->bank_account_number,
                    'bank_account_name' => $request->bank_account_name,
                ]);
            });
        } catch (\Exception $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }

        return response()->json([
            'success' => true,
            'message' => 'Permintaan penarikan dana berhasil dikirim dan sedang diproses.',
            'remaining_coins' => $user->fresh()->coins,
        ]);
    }
}
