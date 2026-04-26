<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('missions', function (Blueprint $table) {
            // Rename title to name
            $table->renameColumn('title', 'name');
            
            // Add new columns
            $table->string('type')->default('daily')->after('description'); // daily, weekly, once
            $table->unsignedInteger('coin_reward')->default(0)->after('xp_reward');
            $table->unsignedInteger('target_count')->default(1)->after('coin_reward');
            
            // Remove old columns
            if (Schema::hasColumn('missions', 'cooldown_seconds')) {
                $table->dropColumn('cooldown_seconds');
            }
            if (Schema::hasColumn('missions', 'daily_limit')) {
                $table->dropColumn('daily_limit');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('missions', function (Blueprint $table) {
            $table->renameColumn('name', 'title');
            $table->dropColumn(['type', 'coin_reward', 'target_count']);
            $table->integer('cooldown_seconds')->nullable();
            $table->integer('daily_limit')->nullable();
        });
    }
};
