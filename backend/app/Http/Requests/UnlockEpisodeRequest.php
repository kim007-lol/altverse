<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class UnlockEpisodeRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        return $this->user() && $this->user()->role === 'reader';
    }

    /**
     * Get the validation rules that apply to the request.
     */
    public function rules(): array
    {
        return [
            // No body parameters needed - episode ID comes from route
        ];
    }

    /**
     * Get custom error messages for validation rules.
     */
    public function messages(): array
    {
        return [];
    }
}
