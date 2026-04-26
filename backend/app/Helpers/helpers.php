<?php

use App\Http\Responses\ApiResponse;

if (!function_exists('api_success')) {
    /**
     * Return success API response.
     */
    function api_success(mixed $data = null, string $message = 'Success', int $statusCode = 200)
    {
        return ApiResponse::success($data, $message, $statusCode);
    }
}

if (!function_exists('api_error')) {
    /**
     * Return error API response.
     */
    function api_error(string $message = 'Error', int $statusCode = 400, mixed $errors = null, mixed $data = null)
    {
        return ApiResponse::error($message, $statusCode, $errors, $data);
    }
}

if (!function_exists('api_validation_error')) {
    /**
     * Return validation error API response.
     */
    function api_validation_error(array $errors, string $message = 'Validasi gagal')
    {
        return ApiResponse::validationError($errors, $message);
    }
}

if (!function_exists('api_not_found')) {
    /**
     * Return not found API response.
     */
    function api_not_found(string $message = 'Resource tidak ditemukan')
    {
        return ApiResponse::notFound($message);
    }
}

if (!function_exists('api_created')) {
    /**
     * Return created API response.
     */
    function api_created(mixed $data = null, string $message = 'Resource berhasil dibuat')
    {
        return ApiResponse::created($data, $message);
    }
}

if (!function_exists('api_paginated')) {
    /**
     * Return paginated API response.
     */
    function api_paginated(mixed $paginator, string $message = 'Success')
    {
        return ApiResponse::paginated($paginator, $message);
    }
}
