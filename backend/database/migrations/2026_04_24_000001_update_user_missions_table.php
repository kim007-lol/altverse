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
        Schema::table('user_missions', function (Blueprint $table) {
            $table->unsignedInteger('progress')->default(0)->after('mission_id');
            $table->timestamp('completed_at')->nullable()->after('progress');
            $table->timestamp('claimed_at')->nullable()->after('completed_at');
            
            // Remove meta column if exists (not used anymore)
            if (Schema::hasColumn('user_missions', 'meta')) {
                $table->dropColumn('meta');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('user_missions', function (Blueprint $table) {
            $table->dropColumn(['progress', 'completed_at', 'claimed_at']);
            $table->jsonb('meta')->nullable();
        });
    }
};
