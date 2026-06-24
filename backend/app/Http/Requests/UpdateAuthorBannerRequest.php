<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class UpdateAuthorBannerRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        return $this->user()->can_customize_banner === true;
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, \Illuminate\Contracts\Validation\ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            'banner' => 'required|image|mimes:jpeg,png,jpg,webp|max:2048',
        ];
    }

    public function messages(): array
    {
        return [
            'banner.required' => 'Banner image wajib diupload',
            'banner.image'    => 'File harus berupa gambar',
            'banner.mimes'    => 'Format harus: JPEG, PNG, JPG, atau WebP',
            'banner.max'      => 'Ukuran maksimal 2MB',
        ];
    }
}
