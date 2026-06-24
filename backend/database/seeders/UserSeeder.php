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
        // 0. Akun Admin
        User::firstOrCreate(
            ['email' => 'admin@gmail.com'],
            [
                'name' => 'Admin AU Reader',
                'password' => Hash::make('Hakim123'),
                'role' => 'admin',
                'email_verified_at' => now(),
            ]
        );

        // 1. Akun Reader
        User::firstOrCreate(
            ['email' => 'reader@gmail.com'],
            [
                'name' => 'Demo Reader',
                'password' => Hash::make('Hakim123'),
                'role' => 'reader',
                'coins' => 100,
                'email_verified_at' => now(),
            ]
        );

        // 2. Akun Author
        User::firstOrCreate(
            ['email' => 'author@gmail.com'],
            [
                'name' => 'Demo Author',
                'password' => Hash::make('Hakim123'),
                'role' => 'author',
                'pen_name' => 'Author Kece',
                'coins' => 500,
                'email_verified_at' => now(),
            ]
        );
        // 3. Akun Hakim (Khusus)
        User::firstOrCreate(
            ['email' => 'ngabdullahhakim@gmail.com'],
            [
                'name' => 'Abdullah Hakim',
                'password' => Hash::make('Hakim123'),
                'role' => 'author',
                'pen_name' => 'Hakim',
                'coins' => 10000,
                'email_verified_at' => now(),
            ]
        );
    }
}
