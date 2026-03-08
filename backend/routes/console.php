<?php

use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Schedule;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

// ─── Scheduled Commands ───
Schedule::command('authors:recalculate-tiers')->dailyAt('03:00');
Schedule::command('season:rotate')->dailyAt('03:30');
Schedule::command('season:recalculate-ranks')->everyThirtyMinutes();
