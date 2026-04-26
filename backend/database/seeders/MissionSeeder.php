<?php

namespace Database\Seeders;

use App\Models\Mission;
use Illuminate\Database\Seeder;

class MissionSeeder extends Seeder
{
    public function run(): void
    {
        $missions = [
            // ─── Daily Missions (No Coins, Pure XP) ───
            [
                'code' => 'daily_login',
                'name' => 'Daily Login',
                'description' => 'Login ke aplikasi hari ini',
                'type' => 'daily',
                'xp_reward' => 10,
                'coin_reward' => 0,
                'target_count' => 1,
                'is_active' => true,
            ],
            [
                'code' => 'daily_read_5',
                'name' => 'Daily Reader',
                'description' => 'Baca 5 episode hari ini',
                'type' => 'daily',
                'xp_reward' => 25,
                'coin_reward' => 0,
                'target_count' => 5,
                'is_active' => true,
            ],
            [
                'code' => 'daily_comment_3',
                'name' => 'Opinionated',
                'description' => 'Tinggalkan 3 komentar hari ini',
                'type' => 'daily',
                'xp_reward' => 20,
                'coin_reward' => 0,
                'target_count' => 3,
                'is_active' => true,
            ],
            [
                'code' => 'daily_like_5',
                'name' => 'Appreciative',
                'description' => 'Like 5 episode hari ini',
                'type' => 'daily',
                'xp_reward' => 15,
                'coin_reward' => 0,
                'target_count' => 5,
                'is_active' => true,
            ],

            // ─── Weekly Missions (No Coins, Pure XP) ───
            [
                'code' => 'weekly_read_25',
                'name' => 'Weekly Bookworm',
                'description' => 'Baca 25 episode minggu ini',
                'type' => 'weekly',
                'xp_reward' => 150,
                'coin_reward' => 0,
                'target_count' => 25,
                'is_active' => true,
            ],
            [
                'code' => 'weekly_comment_15',
                'name' => 'Weekly Critic',
                'description' => 'Tinggalkan 15 komentar minggu ini',
                'type' => 'weekly',
                'xp_reward' => 100,
                'coin_reward' => 0,
                'target_count' => 15,
                'is_active' => true,
            ],
            [
                'code' => 'weekly_follow_5',
                'name' => 'Social Networker',
                'description' => 'Follow 5 author baru minggu ini',
                'type' => 'weekly',
                'xp_reward' => 50,
                'coin_reward' => 0,
                'target_count' => 5,
                'is_active' => true,
            ],
            [
                'code' => 'weekly_bookmark_5',
                'name' => 'Avid Collector',
                'description' => 'Bookmark 5 series minggu ini',
                'type' => 'weekly',
                'xp_reward' => 50,
                'coin_reward' => 0,
                'target_count' => 5,
                'is_active' => true,
            ],
            [
                'code' => 'weekly_streak_7',
                'name' => 'Unbreakable Will',
                'description' => 'Login 7 hari berturut-turut',
                'type' => 'weekly',
                'xp_reward' => 200,
                'coin_reward' => 0,
                'target_count' => 7,
                'is_active' => true,
            ],

            // ─── One-time Missions (Hard Achievements, with Coins) ───
            [
                'code' => 'read_100_episodes',
                'name' => 'Bronze Reader',
                'description' => 'Selesaikan membaca 100 episode',
                'type' => 'once',
                'xp_reward' => 500,
                'coin_reward' => 50,
                'target_count' => 100,
                'is_active' => true,
            ],
            [
                'code' => 'read_500_episodes',
                'name' => 'Silver Reader',
                'description' => 'Selesaikan membaca 500 episode',
                'type' => 'once',
                'xp_reward' => 1000,
                'coin_reward' => 250,
                'target_count' => 500,
                'is_active' => true,
            ],
            [
                'code' => 'read_1000_episodes',
                'name' => 'Gold Reader',
                'description' => 'Selesaikan membaca 1.000 episode',
                'type' => 'once',
                'xp_reward' => 3000,
                'coin_reward' => 1000,
                'target_count' => 1000,
                'is_active' => true,
            ],
            [
                'code' => 'comment_100',
                'name' => 'The Reviewer',
                'description' => 'Tinggalkan total 100 komentar',
                'type' => 'once',
                'xp_reward' => 400,
                'coin_reward' => 100,
                'target_count' => 100,
                'is_active' => true,
            ],
            [
                'code' => 'follow_50_authors',
                'name' => 'Author Supporter',
                'description' => 'Follow 50 author',
                'type' => 'once',
                'xp_reward' => 300,
                'coin_reward' => 100,
                'target_count' => 50,
                'is_active' => true,
            ],
            [
                'code' => 'bookmark_50_series',
                'name' => 'The Librarian',
                'description' => 'Tambahkan 50 series ke bookmark',
                'type' => 'once',
                'xp_reward' => 300,
                'coin_reward' => 100,
                'target_count' => 50,
                'is_active' => true,
            ],
            [
                'code' => 'spend_500_coins',
                'name' => 'Generous Whale',
                'description' => 'Habiskan total 500 koin',
                'type' => 'once',
                'xp_reward' => 500,
                'coin_reward' => 200,
                'target_count' => 500,
                'is_active' => true,
            ],
        ];

        foreach ($missions as $mission) {
            Mission::updateOrCreate(
                ['code' => $mission['code']],
                $mission
            );
        }
    }
}
