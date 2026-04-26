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
     * Get the validation rules that apply to the request.
     */
    public function rules(): array
    {
        return [
            'name'                 => ['sometimes', 'string', 'min:2', 'max:255', Rule::unique('users', 'name')->ignore($this->user()->id)],
            'pen_name'             => ['sometimes', 'string', 'max:255', Rule::unique('users', 'pen_name')->ignore($this->user()->id)],
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
            'name.min'                => 'Nama minimal 2 karakter.',
            'name.max'                => 'Nama maksimal 255 karakter.',
            'name.unique'             => 'Nama (Username) ini sudah digunakan oleh user lain.',
            'pen_name.max'            => 'Pen name maksimal 255 karakter.',
            'pen_name.unique'         => 'Pen name ini sudah digunakan oleh author lain.',
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
