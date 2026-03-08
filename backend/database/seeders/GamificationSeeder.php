<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\SupporterLevel;
use App\Models\Season;

class GamificationSeeder extends Seeder
{
    public function run(): void
    {
        // ─── Supporter Levels ───
        $levels = [
            ['name' => 'Supporter',  'min_spend' => 10,   'weight' => 0,  'icon' => 'seedling', 'color' => '#9e9e9e'],
            ['name' => 'Bronze',     'min_spend' => 100,  'weight' => 5,  'icon' => 'star',     'color' => '#cd7f32'],
            ['name' => 'Silver',     'min_spend' => 500,  'weight' => 10, 'icon' => 'shield',   'color' => '#c0c0c0'],
            ['name' => 'Gold',       'min_spend' => 2000, 'weight' => 20, 'icon' => 'crown',    'color' => '#ffd700'],
            ['name' => 'Diamond',    'min_spend' => 5000, 'weight' => 40, 'icon' => 'diamond',  'color' => '#00e5ff'],
        ];

        foreach ($levels as $level) {
            SupporterLevel::updateOrCreate(
                ['name' => $level['name']],
                $level
            );
        }

        // ─── First Season (if none exists) ───
        if (Season::count() === 0) {
            Season::create([
                'name' => 'Season 1',
                'start_date' => now(),
                'end_date' => now()->addDays(90),
                'is_active' => true,
            ]);
        }
    }
}
