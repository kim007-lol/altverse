<?php

namespace App\Http\Responses;

use Illuminate\Http\JsonResponse;

class ApiResponse
{
    /**
     * Success response with data.
     */
    public static function success(
        mixed $data = null,
        string $message = 'Success',
        int $statusCode = 200
    ): JsonResponse {
        $response = [
            'success' => true,
            'message' => $message,
        ];

        if ($data !== null) {
            $response['data'] = $data;
        }

        return response()->json($response, $statusCode);
    }

    /**
     * Error response with message.
     */
    public static function error(
        string $message = 'Error',
        int $statusCode = 400,
        mixed $errors = null,
        mixed $data = null
    ): JsonResponse {
        $response = [
            'success' => false,
            'message' => $message,
        ];

        if ($errors !== null) {
            $response['errors'] = $errors;
        }

        if ($data !== null) {
            $response['data'] = $data;
        }

        return response()->json($response, $statusCode);
    }

    /**
     * Validation error response.
     */
    public static function validationError(
        array $errors,
        string $message = 'Validasi gagal'
    ): JsonResponse {
        return self::error($message, 422, $errors);
    }

    /**
     * Not found response.
     */
    public static function notFound(
        string $message = 'Resource tidak ditemukan'
    ): JsonResponse {
        return self::error($message, 404);
    }

    /**
     * Unauthorized response.
     */
    public static function unauthorized(
        string $message = 'Unauthorized'
    ): JsonResponse {
        return self::error($message, 401);
    }

    /**
     * Forbidden response.
     */
    public static function forbidden(
        string $message = 'Forbidden'
    ): JsonResponse {
        return self::error($message, 403);
    }

    /**
     * Server error response.
     */
    public static function serverError(
        string $message = 'Internal server error',
        mixed $data = null
    ): JsonResponse {
        return self::error($message, 500, null, $data);
    }

    /**
     * Created response.
     */
    public static function created(
        mixed $data = null,
        string $message = 'Resource berhasil dibuat'
    ): JsonResponse {
        return self::success($data, $message, 201);
    }

    /**
     * No content response.
     */
    public static function noContent(): JsonResponse
    {
        return response()->json(null, 204);
    }

    /**
     * Paginated response.
     */
    public static function paginated(
        mixed $paginator,
        string $message = 'Success'
    ): JsonResponse {
        return response()->json([
            'success' => true,
            'message' => $message,
            'data' => $paginator->items(),
            'pagination' => [
                'current_page' => $paginator->currentPage(),
                'last_page' => $paginator->lastPage(),
                'per_page' => $paginator->perPage(),
                'total' => $paginator->total(),
                'from' => $paginator->firstItem(),
                'to' => $paginator->lastItem(),
            ],
        ]);
    }
}
