<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->jsonb('author_social_links')->nullable()->after('author_bio');
        });

        // Copy existing social_links for users who have role=author
        DB::table('users')
            ->where('role', 'author')
            ->whereNotNull('social_links')
            ->update([
                'author_social_links' => DB::raw('social_links'),
            ]);
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn('author_social_links');
        });
    }
};
