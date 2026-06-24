<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateProfileRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        return $this->user() !== null;
    }

    /**
     * Prepare the data for validation.
     * Multipart forms send social_links as a JSON string — decode it into an array first.
     */
    protected function prepareForValidation(): void
    {
        if ($this->has('social_links') && is_string($this->input('social_links'))) {
            $decoded = json_decode($this->input('social_links'), true);
            if ($decoded !== null) {
                $this->merge(['social_links' => $decoded]);
            }
        }

        if ($this->has('author_social_links') && is_string($this->input('author_social_links'))) {
            $decoded = json_decode($this->input('author_social_links'), true);
            if ($decoded !== null) {
                $this->merge(['author_social_links' => $decoded]);
            }
        }
    }

    /**
     * Get the validation rules that apply to the request.
     */
    public function rules(): array
    {
        return [
            'username'             => ['sometimes', 'string', 'min:3', 'max:30', 'regex:/^[a-z0-9_]+$/', Rule::unique('users', 'username')->ignore($this->user()->id)],
            'name'                 => ['sometimes', 'string', 'min:2', 'max:255'],
            'pen_name'             => ['sometimes', 'string', 'max:255'],
            'bio'                  => ['sometimes', 'nullable', 'string', 'max:1000'],
            'author_bio'           => ['sometimes', 'nullable', 'string', 'max:1000'],
            'avatar'               => ['sometimes', 'image', 'mimes:jpg,jpeg,png,webp', 'max:2048'],
            'social_links'         => ['sometimes', 'nullable', 'array'],
            'author_social_links'  => ['sometimes', 'nullable', 'array'],
            'theme_preference'     => ['sometimes', 'in:dark,light'],
            'theme_color'          => ['sometimes', 'nullable', 'string', 'max:20'],
        ];
    }

    /**
     * Get custom error messages for validation rules.
     */
    public function messages(): array
    {
        return [
            'username.min'            => 'Username minimal 3 karakter.',
            'username.max'            => 'Username maksimal 30 karakter.',
            'username.regex'          => 'Username hanya boleh huruf kecil, angka, dan underscore.',
            'username.unique'         => 'Username ini sudah digunakan.',
            'name.min'                => 'Nama minimal 2 karakter.',
            'name.max'                => 'Nama maksimal 255 karakter.',
            'pen_name.max'            => 'Pen name maksimal 255 karakter.',
            'bio.max'                 => 'Bio maksimal 1000 karakter.',
            'author_bio.max'          => 'Bio author maksimal 1000 karakter.',
            'avatar.image'            => 'Avatar harus berupa gambar.',
            'avatar.mimes'            => 'Avatar harus berformat: jpg, jpeg, png, atau webp.',
            'avatar.max'              => 'Ukuran avatar maksimal 2MB.',
            'social_links.array'      => 'Social links harus berupa array.',
            'author_social_links.array' => 'Author social links harus berupa array.',
            'theme_preference.in'     => 'Theme preference harus dark atau light.',
        ];
    }
}
