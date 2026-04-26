<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreSeriesRequest extends FormRequest
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
     *
     * @return array<string, \Illuminate\Contracts\Validation\ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            'title'       => ['required', 'string', 'max:255'],
            'synopsis'    => ['nullable', 'string', 'max:5000'],
            'genre'       => ['required', 'string', 'max:100'],
            'age_rating'  => ['required', 'in:all,13+,17+,18+'],
            'cover'       => ['nullable', 'image', 'mimes:jpg,jpeg,png,webp', 'max:4096'],
        ];
    }

    /**
     * Get custom error messages for validation rules.
     */
    public function messages(): array
    {
        return [
            'title.required'      => 'Judul series wajib diisi.',
            'title.max'           => 'Judul series maksimal 255 karakter.',
            'synopsis.max'        => 'Synopsis maksimal 5000 karakter.',
            'genre.required'      => 'Genre wajib dipilih.',
            'age_rating.required' => 'Age rating wajib dipilih.',
            'age_rating.in'       => 'Age rating harus salah satu dari: all, 13+, 17+, 18+.',
            'cover.image'         => 'Cover harus berupa gambar.',
            'cover.mimes'         => 'Cover harus berformat: jpg, jpeg, png, atau webp.',
            'cover.max'           => 'Ukuran cover maksimal 4MB.',
        ];
    }
}
