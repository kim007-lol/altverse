<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('badges', function (Blueprint $table) {
            $table->string('condition_type')->nullable()->after('category');  // followers, xp, donation, manual
            $table->unsignedInteger('condition_value')->nullable()->after('condition_type');
            $table->string('color')->nullable()->after('condition_value');
        });
    }

    public function down(): void
    {
        Schema::table('badges', function (Blueprint $table) {
            $table->dropColumn(['condition_type', 'condition_value', 'color']);
        });
    }
};
