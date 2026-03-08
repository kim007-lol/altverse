<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // ─── 1. Season Supporter (reader coins spent per season) ───
        Schema::create('season_supporter', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('season_id')->constrained('seasons')->cascadeOnDelete();
            $table->unsignedBigInteger('total_spent')->default(0);
            $table->unsignedInteger('rank')->default(0);
            $table->timestamps();

            $table->unique(['user_id', 'season_id']);
            $table->index(['season_id', 'total_spent']);
        });

        // ─── 2. Season Author Earning (author coins earned per season) ───
        Schema::create('season_author_earning', function (Blueprint $table) {
            $table->id();
            $table->foreignId('author_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('season_id')->constrained('seasons')->cascadeOnDelete();
            $table->unsignedBigInteger('total_earned')->default(0);
            $table->unsignedInteger('rank')->default(0);
            $table->timestamps();

            $table->unique(['author_id', 'season_id']);
            $table->index(['season_id', 'total_earned']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('season_author_earning');
        Schema::dropIfExists('season_supporter');
    }
};
