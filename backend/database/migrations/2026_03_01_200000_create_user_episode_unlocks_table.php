<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('user_episode_unlocks', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('episode_id')->constrained()->cascadeOnDelete();
            $table->enum('unlock_type', ['coin', 'gift', 'admin'])->default('coin');
            $table->timestamps();

            $table->unique(['user_id', 'episode_id']);
            $table->index('episode_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('user_episode_unlocks');
    }
};
