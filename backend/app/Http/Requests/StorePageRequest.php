<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StorePageRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        $episode = $this->route('episode');
        return $this->user() && 
               $this->user()->role === 'author' && 
               $episode->series->author_id === $this->user()->id;
    }

    /**
     * Get the validation rules that apply to the request.
     */
    public function rules(): array
    {
        return [
            'image_path' => ['required', 'string'],
            'width'      => ['nullable', 'integer', 'min:1', 'max:10000'],
            'height'     => ['nullable', 'integer', 'min:1', 'max:10000'],
            'file_size'  => ['nullable', 'integer', 'min:1', 'max:10485760'], // max 10MB
        ];
    }

    /**
     * Get custom error messages for validation rules.
     */
    public function messages(): array
    {
        return [
            'image_path.required' => 'Path gambar wajib diisi.',
            'width.min'           => 'Lebar gambar minimal 1 pixel.',
            'width.max'           => 'Lebar gambar maksimal 10000 pixel.',
            'height.min'          => 'Tinggi gambar minimal 1 pixel.',
            'height.max'          => 'Tinggi gambar maksimal 10000 pixel.',
            'file_size.max'       => 'Ukuran file maksimal 10MB.',
        ];
    }
}
