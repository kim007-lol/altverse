<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

return new class extends Migration
{
    public function up(): void
    {
        // 1. Add username column (nullable first so we can populate)
        Schema::table('users', function (Blueprint $table) {
            $table->string('username', 50)->nullable()->after('name');
        });

        // 2. Populate username from name (lowercase, no spaces, alphanumeric + underscores)
        $users = DB::table('users')->get();
        foreach ($users as $user) {
            $base = Str::slug($user->name, '_');
            $base = preg_replace('/[^a-z0-9_]/', '', strtolower($base));
            if (strlen($base) < 3) {
                $base = 'user_' . $user->id;
            }

            // Ensure uniqueness
            $username = $base;
            $counter = 1;
            while (DB::table('users')->where('username', $username)->where('id', '!=', $user->id)->exists()) {
                $username = $base . '_' . $counter;
                $counter++;
            }

            DB::table('users')->where('id', $user->id)->update(['username' => $username]);
        }

        // 3. Now make it unique and not-null
        Schema::table('users', function (Blueprint $table) {
            $table->string('username', 50)->nullable(false)->unique()->change();
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn('username');
        });
    }
};
