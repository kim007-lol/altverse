<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Report;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ReportController extends Controller
{
    /**
     * Report content (series, episode, comment) or user
     * POST /reports
     */
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'reportable_type' => 'required|string|in:series,episode,comment,user',
            'reportable_id' => 'required|integer',
            'reason' => 'required|string|in:spam,inappropriate,harassment,copyright,other',
            'description' => 'nullable|string|max:500',
        ], [
            'reportable_type.required' => 'Tipe konten yang dilaporkan wajib diisi.',
            'reportable_type.in' => 'Tipe konten tidak valid.',
            'reportable_id.required' => 'ID konten yang dilaporkan wajib diisi.',
            'reason.required' => 'Alasan laporan wajib diisi.',
            'reason.in' => 'Alasan laporan tidak valid.',
            'description.max' => 'Deskripsi maksimal 500 karakter.',
        ]);
        
        // Check if user already reported this content
        $existingReport = Report::where('reporter_id', $request->user()->id)
            ->where('reportable_type', $validated['reportable_type'])
            ->where('reportable_id', $validated['reportable_id'])
            ->where('status', '!=', 'dismissed')
            ->first();
            
        if ($existingReport) {
            return response()->json([
                'message' => 'Kamu sudah melaporkan konten ini sebelumnya.',
            ], 422);
        }
        
        // Rate limit: max 10 reports per day
        $todayReports = Report::where('reporter_id', $request->user()->id)
            ->whereDate('created_at', today())
            ->count();
            
        if ($todayReports >= 10) {
            return response()->json([
                'message' => 'Kamu sudah mencapai batas maksimal laporan hari ini (10 laporan).',
            ], 429);
        }
        
        $report = Report::create([
            'reporter_id' => $request->user()->id,
            'reportable_type' => $validated['reportable_type'],
            'reportable_id' => $validated['reportable_id'],
            'reason' => $validated['reason'],
            'description' => $validated['description'],
            'status' => 'pending',
        ]);
        
        // Auto-delete comment if reported >= 10 times
        if ($validated['reportable_type'] === 'comment') {
            $reportCount = Report::where('reportable_type', 'comment')
                ->where('reportable_id', $validated['reportable_id'])
                ->count();
                
            if ($reportCount >= 10) {
                $comment = \App\Models\Comment::find($validated['reportable_id']);
                if ($comment) {
                    $comment->delete();
                    
                    // Mark all reports for this comment as resolved
                    Report::where('reportable_type', 'comment')
                        ->where('reportable_id', $validated['reportable_id'])
                        ->update([
                            'status' => 'resolved',
                            'action_taken' => 'auto_deleted_due_to_high_reports'
                        ]);
                }
            }
        }
        
        return response()->json([
            'message' => 'Laporan berhasil dikirim. Tim kami akan meninjau laporan kamu.',
            'report' => $report,
        ], 201);
    }
    
    /**
     * Get user's reports
     * GET /reports
     */
    public function index(Request $request): JsonResponse
    {
        $reports = Report::where('reporter_id', $request->user()->id)
            ->with('reportable')
            ->latest()
            ->paginate(20);
            
        return response()->json($reports);
    }
    
    /**
     * Get report detail
     * GET /reports/{report}
     */
    public function show(Request $request, Report $report): JsonResponse
    {
        // Only reporter can view their own report
        if ($report->reporter_id !== $request->user()->id) {
            return response()->json([
                'message' => 'Kamu tidak memiliki akses ke laporan ini.',
            ], 403);
        }
        
        $report->load('reportable');
        
        return response()->json($report);
    }
    
    /**
     * Cancel report (only if still pending)
     * DELETE /reports/{report}
     */
    public function destroy(Request $request, Report $report): JsonResponse
    {
        // Only reporter can cancel their own report
        if ($report->reporter_id !== $request->user()->id) {
            return response()->json([
                'message' => 'Kamu tidak memiliki akses ke laporan ini.',
            ], 403);
        }
        
        // Can only cancel pending reports
        if ($report->status !== 'pending') {
            return response()->json([
                'message' => 'Laporan yang sudah ditinjau tidak dapat dibatalkan.',
            ], 422);
        }
        
        $report->delete();
        
        return response()->json([
            'message' => 'Laporan berhasil dibatalkan.',
        ]);
    }
    
    /**
     * Get report reasons
     * GET /reports/reasons
     */
    public function reasons(): JsonResponse
    {
        $reasons = [
            'spam' => 'Spam atau konten tidak relevan',
            'inappropriate' => 'Konten tidak pantas atau vulgar',
            'harassment' => 'Pelecehan atau bullying',
            'copyright' => 'Pelanggaran hak cipta',
            'other' => 'Alasan lainnya',
        ];
        
        return response()->json(['reasons' => $reasons]);
    }
}
