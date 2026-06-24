<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class AdminOnly
{
    /**
     * Block non-admins from accessing admin-only endpoints.
     */
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();

        if ($user && $user->role !== 'admin') {
            return response()->json([
                'message' => 'Akses ditolak. Fitur ini hanya tersedia untuk Admin.',
            ], 403);
        }

        return $next($request);
    }
}
