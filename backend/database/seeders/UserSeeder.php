<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use App\Models\User;

class UserSeeder extends Seeder
{
    /**
     * Run the database seeds.
     *
     * @return void
     */
    public function run()
    {
        // 1. Akun Reader
        User::firstOrCreate(
            ['email' => 'reader@test.com'],
            [
                'name' => 'Demo Reader',
                'password' => Hash::make('password'),
                'role' => 'reader',
                'coins' => 100,
                'email_verified_at' => now(),
            ]
        );

        // 2. Akun Author
        User::firstOrCreate(
            ['email' => 'author@test.com'],
            [
                'name' => 'Demo Author',
                'password' => Hash::make('password'),
                'role' => 'author',
                'pen_name' => 'Author Kece',
                'coins' => 500,
                'email_verified_at' => now(),
            ]
        );
    }
}
