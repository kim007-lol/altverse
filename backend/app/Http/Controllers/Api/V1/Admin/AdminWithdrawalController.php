<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Models\Withdrawal;
use App\Models\User;
use App\Models\Transaction;
use App\Models\Notification;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class AdminWithdrawalController extends Controller
{
    /**
     * Tampilkan semua daftar penarikan untuk admin.
     */
    public function index()
    {
        $withdrawals = Withdrawal::with(['user:id,name,pen_name,email,avatar_url'])
            ->orderByRaw("CASE status WHEN 'pending' THEN 1 WHEN 'processing' THEN 2 WHEN 'completed' THEN 3 WHEN 'rejected' THEN 4 ELSE 5 END")
            ->orderBy('created_at', 'desc')
            ->paginate(20);

        return response()->json([
            'success' => true,
            'data' => $withdrawals
        ]);
    }

    /**
     * Proses pengajuan penarikan (approve / reject).
     */
    public function process(Request $request, $id)
    {
        $request->validate([
            'status' => 'required|in:completed,rejected',
            'admin_notes' => 'nullable|string'
        ]);

        $withdrawal = Withdrawal::findOrFail($id);

        if ($withdrawal->status !== 'pending') {
            return response()->json([
                'success' => false,
                'message' => "Penarikan ini sudah diproses ({$withdrawal->status})."
            ], 422);
        }

        try {
            DB::transaction(function () use ($withdrawal, $request) {
                // Kunci tabel withdrawal
                $lockedWithdrawal = Withdrawal::lockForUpdate()->find($withdrawal->id);
                $status = $request->status;

                $lockedWithdrawal->status = $status;
                $lockedWithdrawal->admin_notes = $request->admin_notes;
                $lockedWithdrawal->processed_at = now();
                $lockedWithdrawal->save();

                $author = User::find($lockedWithdrawal->user_id);
                $authorName = $author->pen_name ?? $author->name;

                if ($status === 'completed') {
                    // Beri notifikasi ke Author bahwa penarikan sukses
                    Notification::create([
                        'id' => Str::uuid(),
                        'user_id' => $author->id,
                        'type' => 'withdrawal_completed',
                        'title' => 'Penarikan Dana Berhasil',
                        'body' => "Penarikan sebesar Rp " . number_format($lockedWithdrawal->amount_idr, 0, ',', '.') . " telah ditransfer ke rekening {$lockedWithdrawal->bank_name} Anda.",
                    ]);
                } elseif ($status === 'rejected') {
                    // Refund koin ke Author
                    $lockedAuthor = User::lockForUpdate()->find($author->id);
                    $lockedAuthor->increment('coins', $lockedWithdrawal->amount_coins);

                    // Catat transaksi refund
                    Transaction::create([
                        'user_id' => $lockedAuthor->id,
                        'type' => 'withdrawal_refund',
                        'amount' => $lockedWithdrawal->amount_coins,
                        'description' => "Pengembalian koin dari penarikan dana yang ditolak." . ($request->admin_notes ? " Alasan: {$request->admin_notes}" : ""),
                    ]);

                    // Beri notifikasi ke Author bahwa penarikan ditolak
                    Notification::create([
                        'id' => Str::uuid(),
                        'user_id' => $author->id,
                        'type' => 'withdrawal_rejected',
                        'title' => 'Penarikan Dana Ditolak',
                        'body' => "Penarikan koin gagal diproses. Koin telah dikembalikan ke akun Anda." . ($request->admin_notes ? " Alasan: {$request->admin_notes}" : ""),
                    ]);

                    // Opsional: Tarik koin dari Admin kembali (kalau sebelumnya masuk ke Admin)
                    $adminUser = User::where('email', 'admin@aureader.com')->first();
                    if ($adminUser) {
                        $lockedAdmin = User::lockForUpdate()->find($adminUser->id);
                        $lockedAdmin->decrement('coins', $lockedWithdrawal->amount_coins);
                    }
                }
            });

            return response()->json([
                'success' => true,
                'message' => "Penarikan berhasil di-{$request->status}."
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Terjadi kesalahan: ' . $e->getMessage()
            ], 500);
        }
    }
}
