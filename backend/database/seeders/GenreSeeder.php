<?php

namespace Database\Seeders;

use App\Models\Genre;
use Illuminate\Database\Seeder;
use Illuminate\Support\Str;

class GenreSeeder extends Seeder
{
    public function run(): void
    {
        $genres = [
            ['name' => 'Romance', 'icon' => '💕'],
            ['name' => 'Action', 'icon' => '⚔️'],
            ['name' => 'Fantasy', 'icon' => '🧙'],
            ['name' => 'Horror', 'icon' => '👻'],
            ['name' => 'Comedy', 'icon' => '😂'],
            ['name' => 'Drama', 'icon' => '🎭'],
            ['name' => 'Sci-Fi', 'icon' => '🚀'],
            ['name' => 'Slice of Life', 'icon' => '🌸'],
            ['name' => 'Mystery', 'icon' => '🔍'],
            ['name' => 'Thriller', 'icon' => '😱'],
            ['name' => 'Adventure', 'icon' => '🗺️'],
            ['name' => 'Historical', 'icon' => '🏛️'],
            ['name' => 'BL/GL', 'icon' => '🌈'],
            ['name' => 'School Life', 'icon' => '🏫'],
            ['name' => 'Supernatural', 'icon' => '👁️'],
        ];

        foreach ($genres as $genre) {
            Genre::updateOrCreate(
                ['slug' => Str::slug($genre['name'])],
                array_merge($genre, ['slug' => Str::slug($genre['name'])])
            );
        }
    }
}
