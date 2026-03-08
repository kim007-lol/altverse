<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class ReaderOnly
{
    /**
     * Block authors from accessing reader-only gamification endpoints.
     */
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();

        if ($user && $user->role === 'author') {
            return response()->json([
                'message' => 'Fitur Gamifikasi hanya tersedia untuk Reader. Silakan switch ke Reader terlebih dahulu.',
            ], 403);
        }

        return $next($request);
    }
}
