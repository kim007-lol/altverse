<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('episodes', function (Blueprint $table) {
            $table->string('music_path')->nullable()->after('published_at');
            $table->string('music_title', 100)->nullable()->after('music_path');
        });
    }

    public function down(): void
    {
        Schema::table('episodes', function (Blueprint $table) {
            $table->dropColumn(['music_path', 'music_title']);
        });
    }
};
