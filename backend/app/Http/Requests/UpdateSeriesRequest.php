<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class UpdateSeriesRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        $series = $this->route('series');
        return $this->user() && 
               $this->user()->role === 'author' && 
               $series->author_id === $this->user()->id;
    }

    /**
     * Get the validation rules that apply to the request.
     */
    public function rules(): array
    {
        return [
            'title'       => ['sometimes', 'string', 'max:255'],
            'synopsis'    => ['sometimes', 'nullable', 'string', 'max:5000'],
            'genre'       => ['sometimes', 'string', 'max:100'],
            'age_rating'  => ['sometimes', 'in:all,13+,17+,18+'],
            'status'      => ['sometimes', 'in:draft,published,archived'],
            'cover'       => ['nullable', 'image', 'mimes:jpg,jpeg,png,webp', 'max:4096'],
        ];
    }

    /**
     * Get custom error messages for validation rules.
     */
    public function messages(): array
    {
        return [
            'title.max'           => 'Judul series maksimal 255 karakter.',
            'synopsis.max'        => 'Synopsis maksimal 5000 karakter.',
            'age_rating.in'       => 'Age rating harus salah satu dari: all, 13+, 17+, 18+.',
            'status.in'           => 'Status harus salah satu dari: draft, published, archived.',
            'cover.image'         => 'Cover harus berupa gambar.',
            'cover.mimes'         => 'Cover harus berformat: jpg, jpeg, png, atau webp.',
            'cover.max'           => 'Ukuran cover maksimal 4MB.',
        ];
    }
}
