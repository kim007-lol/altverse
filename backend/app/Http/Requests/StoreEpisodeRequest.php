<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreEpisodeRequest extends FormRequest
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
            'title'          => ['required', 'string', 'max:255'],
            'is_premium'     => ['boolean'],
            'coin_price'     => ['required_if:is_premium,true', 'integer', 'min:0', 'max:1000'],
            'scheduled_at'   => ['nullable', 'date', 'after:now'],
        ];
    }

    /**
     * Get custom error messages for validation rules.
     */
    public function messages(): array
    {
        return [
            'title.required'          => 'Judul episode wajib diisi.',
            'title.max'               => 'Judul episode maksimal 255 karakter.',
            'coin_price.required_if'  => 'Harga koin wajib diisi untuk episode premium.',
            'coin_price.max'          => 'Harga koin maksimal 1000.',
            'scheduled_at.after'      => 'Jadwal publish harus di masa depan.',
        ];
    }
}
