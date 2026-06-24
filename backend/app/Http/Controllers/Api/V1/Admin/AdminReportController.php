<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Report;

class AdminReportController extends Controller
{
    public function index(Request $request)
    {
        $query = Report::with(['reporter']);

        if ($request->has('status')) {
            $query->where('status', $request->status);
        }

        $reports = $query->orderBy('created_at', 'desc')->paginate(20);

        // Append reportable details (Series, Episode, Comment, or User)
        $reports->getCollection()->transform(function ($report) {
            $report->target = $report->reportable;
            return $report;
        });

        return response()->json($reports);
    }

    public function resolve(Request $request, Report $report)
    {
        $request->validate([
            'status' => 'required|in:resolved,dismissed,rejected,resolved_delete,resolved_ban',
            'action_taken' => 'nullable|string'
        ]);

        $action = $request->status;
        $report->status = in_array($action, ['resolved_delete', 'resolved_ban']) ? 'resolved' : $action;
        $report->action_taken = $request->action_taken ?? $action;
        $report->save();

        if ($action === 'resolved_delete') {
            if ($report->reportable) {
                // Delete the reported content (Episode, Comment, User, Series)
                $report->reportable->delete();
            }
        } elseif ($action === 'resolved_ban') {
            $target = $report->reportable;
            $userToBan = null;

            if ($target instanceof \App\Models\User) {
                $userToBan = $target;
            } elseif (isset($target->user_id)) {
                $userToBan = \App\Models\User::find($target->user_id);
            } elseif ($target instanceof \App\Models\Episode && $target->series) {
                $userToBan = \App\Models\User::find($target->series->author_id);
            } elseif ($target instanceof \App\Models\Series) {
                $userToBan = \App\Models\User::find($target->author_id);
            }

            if ($userToBan) {
                $userToBan->status = 'banned';
                $userToBan->save();
            }
        }

        return response()->json([
            'message' => "Report resolved with action: {$action}",
            'report' => $report
        ]);
    }
}
