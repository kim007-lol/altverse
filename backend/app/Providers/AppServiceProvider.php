<?php

namespace App\Providers;

use Illuminate\Database\Eloquent\Relations\Relation;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        // Register morph map for polymorphic relationships
        Relation::enforceMorphMap([
            'series' => \App\Models\Series::class,
            'episode' => \App\Models\Episode::class,
            'comment' => \App\Models\Comment::class,
            'user' => \App\Models\User::class,
        ]);
    }
}
