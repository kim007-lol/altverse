<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\User;
use App\Models\Series;
use App\Models\Report;
use App\Models\Withdrawal;
use App\Models\Transaction;

class AdminDashboardController extends Controller
{
    public function overview()
    {
        $totalUsers = User::where('role', 'reader')->count();
        $totalAuthors = User::where('role', 'author')->count();
        $totalSeries = Series::count();
        $pendingWithdrawals = Withdrawal::where('status', 'pending')->count();
        $pendingReports = Report::where('status', 'pending')->count();
        
        // Asumsi ada tabel transactions, jika tidak ada fallback ke koin
        $totalRevenue = User::sum('lifetime_spend'); // atau logika revenue lain yang sesuai
        
        return response()->json([
            'total_users' => $totalUsers,
            'total_authors' => $totalAuthors,
            'total_series' => $totalSeries,
            'pending_withdrawals' => $pendingWithdrawals,
            'pending_reports' => $pendingReports,
            'total_revenue' => $totalRevenue,
        ]);
    }
}
