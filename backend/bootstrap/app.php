<?php

use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__ . '/../routes/web.php',
        api: __DIR__ . '/../routes/api.php',
        commands: __DIR__ . '/../routes/console.php',
        health: '/up',
        apiPrefix: 'api',
    )
    ->withMiddleware(function (Middleware $middleware): void {
        $middleware->statefulApi();
        $middleware->alias([
            'reader-only' => \App\Http\Middleware\ReaderOnly::class,
            'author-only' => \App\Http\Middleware\AuthorOnly::class,
            'admin-only' => \App\Http\Middleware\AdminOnly::class,
        ]);
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        // Handle validation exceptions
        $exceptions->renderable(function (\Illuminate\Validation\ValidationException $e, $request) {
            if ($request->expectsJson()) {
                return \App\Http\Responses\ApiResponse::validationError(
                    $e->errors(),
                    $e->getMessage()
                );
            }
        });

        // Handle model not found exceptions
        $exceptions->renderable(function (\Illuminate\Database\Eloquent\ModelNotFoundException $e, $request) {
            if ($request->expectsJson()) {
                return \App\Http\Responses\ApiResponse::notFound(
                    'Resource tidak ditemukan'
                );
            }
        });

        // Handle authentication exceptions
        $exceptions->renderable(function (\Illuminate\Auth\AuthenticationException $e, $request) {
            if ($request->expectsJson()) {
                return \App\Http\Responses\ApiResponse::unauthorized(
                    'Unauthenticated'
                );
            }
        });

        // Handle authorization exceptions
        $exceptions->renderable(function (\Illuminate\Auth\Access\AuthorizationException $e, $request) {
            if ($request->expectsJson()) {
                return \App\Http\Responses\ApiResponse::forbidden(
                    'Forbidden'
                );
            }
        });

        // Handle HTTP exceptions
        $exceptions->renderable(function (\Symfony\Component\HttpKernel\Exception\HttpException $e, $request) {
            if ($request->expectsJson()) {
                return \App\Http\Responses\ApiResponse::error(
                    $e->getMessage() ?: 'Error',
                    $e->getStatusCode()
                );
            }
        });

        // Handle general exceptions in production
        $exceptions->renderable(function (\Throwable $e, $request) {
            if ($request->expectsJson() && !config('app.debug')) {
                return \App\Http\Responses\ApiResponse::serverError(
                    'Terjadi kesalahan pada server'
                );
            }
        });
    })->create();
