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

        // Menggunakan Aturan Emas: Cek kepemilikan pen_name, bukan sekadar role aktif.
        if ($user && empty($user->pen_name)) {
            return response()->json([
                'message' => 'Fitur ini hanya tersedia untuk Author. Silakan buat profil Author terlebih dahulu.',
            ], 403);
        }

        return $next($request);
    }
}
