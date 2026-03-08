<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->unsignedInteger('followers_count')->default(0)->after('author_tier');
            $table->unsignedBigInteger('total_views')->default(0)->after('followers_count');
            $table->unsignedInteger('published_episode_count')->default(0)->after('total_views');
            $table->boolean('can_customize_banner')->default(false)->after('published_episode_count');
            $table->boolean('can_tip')->default(false)->after('can_customize_banner');
            $table->boolean('is_verified')->default(false)->after('can_tip');
            $table->timestamp('tier_updated_at')->nullable()->after('is_verified');
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn([
                'followers_count',
                'total_views',
                'published_episode_count',
                'can_customize_banner',
                'can_tip',
                'is_verified',
                'tier_updated_at',
            ]);
        });
    }
};
