<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class UpdateEpisodeRequest extends FormRequest
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
            'title'        => ['sometimes', 'string', 'max:255'],
            'is_premium'   => ['sometimes', 'boolean'],
            'coin_price'   => ['sometimes', 'integer', 'min:0', 'max:1000'],
            'scheduled_at' => ['nullable', 'date', 'after:now'],
            'music_path'   => ['sometimes', 'nullable', 'string'],
            'music_title'  => ['sometimes', 'nullable', 'string', 'max:100'],
        ];
    }

    /**
     * Get custom error messages for validation rules.
     */
    public function messages(): array
    {
        return [
            'title.max'           => 'Judul episode maksimal 255 karakter.',
            'coin_price.max'      => 'Harga koin maksimal 1000.',
            'scheduled_at.after'  => 'Jadwal publish harus di masa depan.',
        ];
    }
}
