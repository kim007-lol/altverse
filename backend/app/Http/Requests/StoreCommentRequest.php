<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreCommentRequest extends FormRequest
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
            'body'      => ['required', 'string', 'min:10', 'max:2000'],
            'parent_id' => ['nullable', 'exists:comments,id'],
        ];
    }

    /**
     * Get custom error messages for validation rules.
     */
    public function messages(): array
    {
        return [
            'body.required' => 'Komentar wajib diisi.',
            'body.min'      => 'Komentar minimal 10 karakter.',
            'body.max'      => 'Komentar maksimal 2000 karakter.',
            'parent_id.exists' => 'Komentar parent tidak ditemukan.',
        ];
    }
}
