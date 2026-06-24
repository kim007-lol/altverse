<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\UpdateAuthorBannerRequest;
use App\Jobs\OptimizeImageJob;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Cache;

class ProfileController extends Controller
{
    public function uploadBanner(UpdateAuthorBannerRequest $request): JsonResponse
    {
        $user = $request->user();
        
        if (!$user->can_customize_banner) {
            return response()->json([
                'message' => 'Banner customization requires Silver tier or higher'
            ], 403);
        }
        
        if ($user->author_banner_url) {
            Storage::disk('s3')->delete($user->author_banner_url);
        }
        
        $file = $request->file('banner');
        $filename = 'banners/' . uniqid() . '_' . time() . '.' . $file->getClientOriginalExtension();
        $path = Storage::disk('s3')->putFileAs('', $file, $filename, 'public');
        
        $user->update(['author_banner_url' => $path]);
        Cache::forget("author:{$user->id}:profile");
        
        OptimizeImageJob::dispatch($path, 1200, 400);
        
        return response()->json([
            'message' => 'Banner berhasil diupload',
            'banner_url' => Storage::disk('s3')->url($path),
        ]);
    }

    public function deleteBanner(Request $request): JsonResponse
    {
        $user = $request->user();
        
        if (!$user->author_banner_url) {
            return response()->json(['message' => 'Tidak ada banner untuk dihapus'], 404);
        }
        
        Storage::disk('s3')->delete($user->author_banner_url);
        
        $user->update(['author_banner_url' => null]);
        Cache::forget("author:{$user->id}:profile");
        
        return response()->json(['message' => 'Banner berhasil dihapus']);
    }
}
