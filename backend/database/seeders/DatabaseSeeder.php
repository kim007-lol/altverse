<?php

namespace Database\Seeders;

use App\Models\Genre;
use App\Models\Badge;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        $this->call([
            GenreSeeder::class,
            GamificationSeeder::class,
            BadgeSeeder::class,
            MissionSeeder::class,
            UserSeeder::class,
        ]);
    }
}
