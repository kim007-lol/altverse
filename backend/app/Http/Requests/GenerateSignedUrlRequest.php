<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class GenerateSignedUrlRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        return $this->user() && $this->user()->role === 'author';
    }

    /**
     * Get the validation rules that apply to the request.
     */
    public function rules(): array
    {
        return [
            'filename' => ['required', 'string', 'max:255'],
            'type'     => ['required', 'string', 'in:image/jpeg,image/png,image/webp,image/gif,audio/mpeg,audio/mp3,audio/mpeg3'],
        ];
    }

    /**
     * Get custom error messages for validation rules.
     */
    public function messages(): array
    {
        return [
            'filename.required' => 'Nama file wajib diisi.',
            'filename.max'      => 'Nama file maksimal 255 karakter.',
            'type.required'     => 'Tipe file wajib diisi.',
            'type.in'           => 'Tipe file harus salah satu dari: image/jpeg, image/png, image/webp, image/gif, audio/mpeg, audio/mp3.',
        ];
    }
}
