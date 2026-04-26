<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class SendTipRequest extends FormRequest
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
            'author_id' => ['required', 'exists:users,id'],
            'amount'    => ['required', 'integer', 'min:1', 'max:10000'],
            'series_id' => ['nullable', 'exists:series,id'],
        ];
    }

    /**
     * Get custom error messages for validation rules.
     */
    public function messages(): array
    {
        return [
            'author_id.required' => 'Author ID wajib diisi.',
            'author_id.exists'   => 'Author tidak ditemukan.',
            'amount.required'    => 'Jumlah tip wajib diisi.',
            'amount.min'         => 'Jumlah tip minimal 1 koin.',
            'amount.max'         => 'Jumlah tip maksimal 10000 koin.',
            'series_id.exists'   => 'Series tidak ditemukan.',
        ];
    }
}
