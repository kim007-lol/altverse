<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Cache;
use Illuminate\Validation\Rules\Password;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    /** Register (2-step: data dasar + role) */
    public function register(Request $request): JsonResponse
    {
        try {
            $validated = $request->validate([
                'name'     => ['required', 'string', 'min:2', 'max:255'],
                'email'    => ['required', 'email:rfc,dns', 'unique:users,email', 'max:255'],
                'password' => ['required', 'confirmed', Password::min(8)->mixedCase()->numbers()],
                'role'     => ['required', 'in:reader,author'],
                'pen_name' => ['nullable', 'required_if:role,author', 'string', 'min:2', 'max:255'],
                'bio'      => ['nullable', 'string', 'max:1000'],
            ], [
                // Pesan error kustom bahasa Indonesia
                'name.required'           => 'Nama wajib diisi.',
                'name.min'                => 'Nama minimal 2 karakter.',
                'email.required'          => 'Email wajib diisi.',
                'email.email'             => 'Format email tidak valid.',
                'email.unique'            => 'Email ini sudah terdaftar.',
                'password.required'       => 'Password wajib diisi.',
                'password.confirmed'      => 'Konfirmasi password tidak cocok.',
                'password.min'            => 'Password minimal 8 karakter.',
                'role.required'           => 'Pilih role (Reader atau Author).',
                'role.in'                 => 'Role harus reader atau author.',
                'pen_name.required_if'    => 'Pen Name wajib diisi untuk Author.',
                'pen_name.min'            => 'Pen Name minimal 2 karakter.',
            ]);
        } catch (ValidationException $e) {
            return response()->json([
                'message' => 'Validasi gagal',
                'errors'  => $e->errors(),
            ], 422);
        }

        $user = User::create([
            'name'     => $validated['name'],
            'email'    => $validated['email'],
            'password' => $validated['password'],
            'pen_name' => $validated['pen_name'] ?? null,
            'bio'      => $validated['bio'] ?? null,
        ]);

        // Explicitly set guarded fields (not mass-assignable)
        $user->role = $validated['role'];
        $user->coins = 100;
        $user->save();

        $token = $user->createToken('mobile-app')->plainTextToken;

        return response()->json([
            'message' => 'Registrasi berhasil',
            'user'    => $user->only(['id', 'name', 'email', 'role', 'pen_name', 'coins']),
            'token'   => $token,
        ], 201);
    }

    /** Login */
    public function login(Request $request): JsonResponse
    {
        try {
            $validated = $request->validate([
                'email'    => ['required', 'email', 'max:255'],
                'password' => ['required', 'string', 'min:1'],
            ], [
                'email.required'    => 'Email wajib diisi.',
                'email.email'       => 'Format email tidak valid.',
                'password.required' => 'Password wajib diisi.',
            ]);
        } catch (ValidationException $e) {
            return response()->json([
                'message' => 'Validasi gagal',
                'errors'  => $e->errors(),
            ], 422);
        }

        $user = User::where('email', $validated['email'])->first();

        if (!$user || !Hash::check($validated['password'], $user->password)) {
            return response()->json([
                'message' => 'Email atau password salah.',
            ], 401);
        }

        // Hapus token lama (satu device satu sesi)
        $user->tokens()->delete();
        $token = $user->createToken('mobile-app')->plainTextToken;

        return response()->json([
            'message' => 'Login berhasil',
            'user'    => $user->only(['id', 'name', 'email', 'role', 'pen_name', 'avatar_url', 'author_avatar_url', 'coins', 'level', 'author_tier', 'theme_preference']),
            'token'   => $token,
            'has_reader_profile' => !empty($user->name),
            'has_author_profile' => !empty($user->pen_name),
        ]);
    }

    /** Logout */
    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json(['message' => 'Logout berhasil']);
    }

    /** Get current user profile */
    public function me(Request $request): JsonResponse
    {
        $user = $request->user();
        $user->loadCount('series');
        $user->load(['badges' => function ($query) {
            $query->wherePivot('is_pinned', true);
        }]);

        $fields = [
            'id',
            'name',
            'email',
            'role',
            'pen_name',
            'avatar_url',
            'author_avatar_url',
            'author_bio',
            'coins',
            'level',
            'exp_points',
            'author_tier',
            'theme_preference',
            'bio',
            'social_links',
            'author_social_links',
            'followers_count',
            'total_views',
            'published_episode_count',
            'can_customize_banner',
            'can_tip',
            'is_verified',
        ];

        $data = $user->only($fields);
        $data['series_count'] = $user->series_count ?? 0;
        $data['pinned_badges'] = $user->badges->toArray();
        $data['has_reader_profile'] = !empty($user->name);
        $data['has_author_profile'] = !empty($user->pen_name);

        return response()->json(['user' => $data]);
    }

    /** Switch role (reader ↔ author) */
    public function switchRole(Request $request): JsonResponse
    {
        $user = $request->user();

        try {
            $rules = [
                'role'     => ['required', 'in:reader,author'],
            ];

            // If switching TO author
            if ($request->input('role') === 'author') {
                // pen_name only required if user doesn't have one yet (first-time author onboarding)
                if (empty($user->pen_name)) {
                    $rules['pen_name'] = ['required', 'string', 'min:2', 'max:255'];
                } else {
                    $rules['pen_name'] = ['nullable', 'string', 'min:2', 'max:255'];
                }
                $rules['author_bio'] = ['nullable', 'string', 'max:1000'];
                $rules['author_avatar_url'] = ['nullable', 'string'];
            }

            // If switching TO reader, allow optional name change
            if ($request->input('role') === 'reader') {
                $rules['name'] = ['nullable', 'string', 'min:2', 'max:255'];
            }

            $validated = $request->validate($rules);
        } catch (ValidationException $e) {
            return response()->json([
                'message' => 'Validasi gagal',
                'errors'  => $e->errors(),
            ], 422);
        }

        $updateData = ['role' => $validated['role']];

        if ($validated['role'] === 'author') {
            if (!empty($validated['pen_name'])) {
                $updateData['pen_name'] = $validated['pen_name'];
            }
            if (isset($validated['author_bio'])) {
                $updateData['author_bio'] = $validated['author_bio'];
            }
            if (isset($validated['author_avatar_url'])) {
                $updateData['author_avatar_url'] = $validated['author_avatar_url'];
            }
        }

        if ($validated['role'] === 'reader') {
            if (!empty($validated['name'])) {
                $updateData['name'] = $validated['name'];
            }
        }

        // Separate guarded vs fillable fields
        $guardedFields = ['role'];
        foreach ($guardedFields as $gf) {
            if (isset($updateData[$gf])) {
                $user->{$gf} = $updateData[$gf];
                unset($updateData[$gf]);
            }
        }
        if (!empty($updateData)) {
            $user->update($updateData);
        }
        if ($user->isDirty()) {
            $user->save();
        }

        $freshUser = $user->fresh();

        return response()->json([
            'message' => 'Role berhasil diubah ke ' . $validated['role'],
            'user'    => $freshUser->only(['id', 'name', 'email', 'role', 'pen_name', 'avatar_url', 'author_avatar_url', 'author_bio', 'coins', 'level']),
            'has_reader_profile' => !empty($freshUser->name),
            'has_author_profile' => !empty($freshUser->pen_name),
        ]);
    }

    /** Update profile (termasuk social links & avatar upload) */
    public function updateProfile(Request $request): JsonResponse
    {
        $user = $request->user();
        $isAuthor = $user->role === 'author';

        // Pre-process JSON string from multipart into array
        if ($request->has('social_links') && is_string($request->input('social_links'))) {
            $decoded = json_decode($request->input('social_links'), true);
            if ($decoded !== null) {
                $request->merge(['social_links' => $decoded]);
            }
        }

        if ($request->has('author_social_links') && is_string($request->input('author_social_links'))) {
            $decoded = json_decode($request->input('author_social_links'), true);
            if ($decoded !== null) {
                $request->merge(['author_social_links' => $decoded]);
            }
        }

        try {
            $validated = $request->validate([
                'name'                 => ['sometimes', 'string', 'min:2', 'max:255'],
                'pen_name'             => ['sometimes', 'string', 'max:255'],
                'bio'                  => ['sometimes', 'nullable', 'string', 'max:1000'],
                'author_bio'           => ['sometimes', 'nullable', 'string', 'max:1000'],
                'avatar'               => ['sometimes', 'image', 'mimes:jpg,jpeg,png,webp', 'max:2048'],
                'social_links'         => ['sometimes', 'nullable', 'array'],
                'author_social_links'  => ['sometimes', 'nullable', 'array'],
                'theme_preference'     => ['sometimes', 'in:dark,light'],
            ]);
        } catch (ValidationException $e) {
            return response()->json([
                'message' => 'Validasi gagal',
                'errors'  => $e->errors(),
            ], 422);
        }

        // Handle avatar file upload — route to role-specific field
        if ($request->hasFile('avatar')) {
            $file = $request->file('avatar');
            $extension = $file->getClientOriginalExtension();
            $rolePrefix = $isAuthor ? 'author' : 'reader';
            $filename = "{$rolePrefix}_avatar_{$user->id}.{$extension}";

            $path = $file->storeAs('avatars', $filename, 's3');

            if ($isAuthor) {
                $validated['author_avatar_url'] = $path;
            } else {
                $validated['avatar_url'] = $path;
            }
            unset($validated['avatar']);
        }

        // Remove null social_links that was injected for author redirect
        if (array_key_exists('social_links', $validated) && $validated['social_links'] === null) {
            unset($validated['social_links']);
        }

        // Guard: strictly allow only role-appropriate fields
        $readerOnlyFields = ['name', 'bio', 'avatar_url', 'social_links'];
        $authorOnlyFields = ['pen_name', 'author_bio', 'author_avatar_url', 'author_social_links'];
        $sharedFields     = ['theme_preference'];

        if ($isAuthor) {
            $allowedFields = array_merge($authorOnlyFields, $sharedFields);
        } else {
            $allowedFields = array_merge($readerOnlyFields, $sharedFields);
        }

        $filteredData = \Illuminate\Support\Arr::only($validated, $allowedFields);

        $user->update($filteredData);

        if ($isAuthor) {
            Cache::forget("author:{$user->id}:profile");
        }

        $freshUser = $user->fresh();

        return response()->json([
            'message' => 'Profil berhasil diperbarui',
            'user'    => $freshUser->only([
                'id',
                'name',
                'email',
                'role',
                'pen_name',
                'avatar_url',
                'author_avatar_url',
                'bio',
                'author_bio',
                'social_links',
                'author_social_links',
                'coins',
                'level',
                'theme_preference',
            ]),
        ]);
    }
}
