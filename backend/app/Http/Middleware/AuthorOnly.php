<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class AuthorOnly
{
    /**
     * Block readers from accessing author-only endpoints.
     */
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();

        if ($user && $user->role !== 'author') {
            return response()->json([
                'message' => 'Fitur ini hanya tersedia untuk Author. Silakan switch ke Author terlebih dahulu.',
            ], 403);
        }

        return $next($request);
    }
}
