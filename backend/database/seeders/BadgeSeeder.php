<?php

namespace Database\Seeders;

use App\Models\Badge;
use Illuminate\Database\Seeder;

class BadgeSeeder extends Seeder
{
    public function run(): void
    {
        $badges = [
            // ─── Reader badges ───
            ['key' => 'read_10_chapters', 'name' => 'Bookworm', 'description' => 'Membaca 10 chapter', 'category' => 'reader'],
            ['key' => 'read_50_chapters', 'name' => 'Avid Reader', 'description' => 'Membaca 50 chapter', 'category' => 'reader'],
            ['key' => 'read_100_chapters', 'name' => 'Scholar', 'description' => 'Membaca 100 chapter', 'category' => 'reader'],
            ['key' => 'follow_5_authors', 'name' => 'Social Butterfly', 'description' => 'Follow 5 author', 'category' => 'reader'],
            ['key' => 'follow_20_authors', 'name' => 'Networker', 'description' => 'Follow 20 author', 'category' => 'reader'],
            ['key' => 'finish_1_au', 'name' => 'Completionist', 'description' => 'Menyelesaikan 1 AU', 'category' => 'reader'],
            ['key' => 'finish_10_au', 'name' => 'Marathoner', 'description' => 'Menyelesaikan 10 AU', 'category' => 'reader'],
            ['key' => 'first_bookmark', 'name' => 'Collector', 'description' => 'Bookmark pertama', 'category' => 'reader'],
            ['key' => 'first_comment', 'name' => 'Vocal Reader', 'description' => 'Komentar pertama', 'category' => 'reader'],
            ['key' => 'streak_7_days', 'name' => 'Consistent', 'description' => '7 hari berturut-turut membaca', 'category' => 'reader'],

            // ─── Author badges (existing) ───
            ['key' => 'first_au', 'name' => 'Debut Author', 'description' => 'Upload AU pertama', 'category' => 'author'],
            ['key' => 'au_1000_views', 'name' => 'Rising Star', 'description' => 'AU mencapai 1000 views', 'category' => 'author'],
            ['key' => 'au_10000_views', 'name' => 'Trending Author', 'description' => 'AU mencapai 10.000 views', 'category' => 'author'],
            ['key' => 'gain_100_followers', 'name' => 'Influencer', 'description' => 'Mendapatkan 100 followers', 'category' => 'author'],
            ['key' => 'complete_au', 'name' => 'Storyteller', 'description' => 'Menyelesaikan 1 AU (status: completed)', 'category' => 'author'],

            // ─── Author Follower Badges (automated, with conditions) ───
            [
                'key'             => 'rising_author',
                'name'            => 'Rising Author',
                'description'     => 'Reached 100 followers',
                'category'        => 'author',
                'condition_type'  => 'followers',
                'condition_value' => 100,
                'color'           => '#CD7F32',
            ],
            [
                'key'             => 'popular_author',
                'name'            => 'Popular Author',
                'description'     => 'Reached 1,000 followers',
                'category'        => 'author',
                'condition_type'  => 'followers',
                'condition_value' => 1000,
                'color'           => '#C0C0C0',
            ],
            [
                'key'             => 'star_author',
                'name'            => 'Star Author',
                'description'     => 'Reached 10,000 followers',
                'category'        => 'author',
                'condition_type'  => 'followers',
                'condition_value' => 10000,
                'color'           => '#FFD700',
            ],
            [
                'key'             => 'influencer_author',
                'name'            => 'Influencer Author',
                'description'     => 'Reached 50,000 followers',
                'category'        => 'author',
                'condition_type'  => 'followers',
                'condition_value' => 50000,
                'color'           => '#9B59B6',
            ],
            [
                'key'             => 'legendary_author',
                'name'            => 'Legendary Author',
                'description'     => 'Reached 100,000 followers',
                'category'        => 'author',
                'condition_type'  => 'followers',
                'condition_value' => 100000,
                'color'           => '#E74C3C',
            ],
            // ─── Lifetime Supporter Badges ───
            [
                'key'             => 'lifetime_perak',
                'name'            => 'Perak Supporter',
                'description'     => 'Total spend 500 coins',
                'category'        => 'reader',
                'condition_type'  => 'spend',
                'condition_value' => 500,
                'color'           => '#C0C0C0',
            ],
            [
                'key'             => 'lifetime_emas',
                'name'            => 'Emas Supporter',
                'description'     => 'Total spend 1,000 coins',
                'category'        => 'reader',
                'condition_type'  => 'spend',
                'condition_value' => 1000,
                'color'           => '#FFD700',
            ],
            [
                'key'             => 'lifetime_diamond',
                'name'            => 'Diamond Supporter',
                'description'     => 'Total spend 2,000 coins',
                'category'        => 'reader',
                'condition_type'  => 'spend',
                'condition_value' => 2000,
                'color'           => '#00FFFF',
            ],
            [
                'key'             => 'lifetime_platinum',
                'name'            => 'Platinum Supporter',
                'description'     => 'Total spend 5,000 coins',
                'category'        => 'reader',
                'condition_type'  => 'spend',
                'condition_value' => 5000,
                'color'           => '#E5E4E2',
            ],
            [
                'key'             => 'lifetime_legendary',
                'name'            => 'Legendary Supporter',
                'description'     => 'Total spend 10,000 coins',
                'category'        => 'reader',
                'condition_type'  => 'spend',
                'condition_value' => 10000,
                'color'           => '#FF00FF',
            ],
        ];

        foreach ($badges as $badge) {
            Badge::updateOrCreate(['key' => $badge['key']], $badge);
        }
    }
}
