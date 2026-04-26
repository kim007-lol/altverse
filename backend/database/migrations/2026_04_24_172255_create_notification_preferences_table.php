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
        Schema::create('notification_preferences', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->string('notification_type'); // new_episode, new_follower, comment_reply, etc.
            $table->boolean('enabled')->default(true);
            $table->boolean('push_enabled')->default(true);
            $table->boolean('email_enabled')->default(false);
            $table->timestamps();
            
            $table->unique(['user_id', 'notification_type']);
            $table->index('user_id');
        });
        
        // Add grouping support to notifications table
        Schema::table('notifications', function (Blueprint $table) {
            $table->string('group_key')->nullable()->after('type');
            $table->index('group_key');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('notifications', function (Blueprint $table) {
            $table->dropIndex(['group_key']);
            $table->dropColumn('group_key');
        });
        
        Schema::dropIfExists('notification_preferences');
    }
};
