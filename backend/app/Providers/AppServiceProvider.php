<?php

namespace App\Providers;

use App\Models\Notification;
use App\Models\Page;
use App\Observers\NotificationObserver;
use App\Observers\PageObserver;
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

        // Push notifications to Go WebSocket via Redis pub/sub
        Notification::observe(NotificationObserver::class);

        // Queue uploaded pages for background image optimization via Go
        Page::observe(PageObserver::class);
    }
}
