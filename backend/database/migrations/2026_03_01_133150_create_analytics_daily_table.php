<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('analytics_daily', function (Blueprint $table) {
            $table->id();
            $table->date('date');
            $table->foreignId('series_id')->constrained('series')->cascadeOnDelete();
            $table->foreignId('episode_id')->nullable()->constrained('episodes')->cascadeOnDelete();
            $table->unsignedInteger('views')->default(0);
            $table->unsignedInteger('reads')->default(0);
            $table->unsignedInteger('new_followers')->default(0);
            $table->timestamps();

            $table->unique(['date', 'series_id', 'episode_id']);
            $table->index(['series_id', 'date']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('analytics_daily');
    }
};
