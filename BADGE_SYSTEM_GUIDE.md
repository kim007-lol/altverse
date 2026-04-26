# 🏆 Badge System Guide - AU Reader

**Date**: 2026-04-26
**Status**: ✅ FULLY IMPLEMENTED

---

## 📋 Overview

Badge system memberikan penghargaan kepada user (reader & author) berdasarkan aktivitas mereka di platform. Badge otomatis diberikan saat user mencapai milestone tertentu.

---

## 🎯 Cara Mendapatkan Badge sebagai Reader

### 1. Reading Badges (Membaca Episode)

Badge ini didapat dengan membaca episode hingga selesai (progress 100%).

**Milestone**:

- 🔖 **Read 10 Chapters**: Baca 10 episode hingga selesai
- 📚 **Read 50 Chapters**: Baca 50 episode hingga selesai
- 📖 **Read 100 Chapters**: Baca 100 episode hingga selesai

**Cara Mendapatkan**:

1. Buka series apa saja
2. Baca episode hingga halaman terakhir
3. Badge otomatis diberikan saat mencapai milestone

**Trigger**: Otomatis saat progress reading = 100%
**Location**: `ReadingController@updateProgress`

---

### 2. Social Badges (Follow Authors)

Badge ini didapat dengan follow author.

**Milestone**:

- 👥 **Follow 5 Authors**: Follow 5 author berbeda
- 🌟 **Follow 20 Authors**: Follow 20 author berbeda

**Cara Mendapatkan**:

1. Buka profile author
2. Klik tombol "Follow"
3. Badge otomatis diberikan saat mencapai milestone

**Trigger**: Otomatis saat follow author
**Location**: `FollowController@toggle`

---

### 3. First Action Badges

Badge ini didapat saat pertama kali melakukan aksi tertentu.

#### 💬 First Comment

**Cara Mendapatkan**:

1. Buka episode apa saja
2. Tulis komentar pertama kamu
3. Submit komentar
4. Badge otomatis diberikan

**Trigger**: Otomatis saat submit komentar pertama
**Location**: `CommentController@store`

#### 🔖 First Bookmark

**Cara Mendapatkan**:

1. Buka series apa saja
2. Klik tombol bookmark
3. Badge otomatis diberikan

**Trigger**: Otomatis saat bookmark pertama
**Location**: `BookmarkController@toggle`

---

### 4. Spending Badges (Unlock Episode)

Badge ini didapat dengan menggunakan coins untuk unlock episode premium.

**Milestone**:

- 💰 **Spend 100 Coins**: Total spending 100 coins
- 💎 **Spend 500 Coins**: Total spending 500 coins
- 👑 **Spend 1000 Coins**: Total spending 1000 coins

**Cara Mendapatkan**:

1. Buka episode premium (locked)
2. Klik "Unlock for X Coins"
3. Confirm unlock
4. Badge otomatis diberikan saat total spending mencapai milestone

**Trigger**: Otomatis saat unlock episode
**Location**: `EpisodeUnlockController@unlock`

---

## 🎨 Cara Mendapatkan Badge sebagai Author

### 1. Follower Badges

Badge ini didapat berdasarkan jumlah followers.

**Milestone**:

- 🌱 **10 Followers**: Dapatkan 10 followers
- 🌿 **50 Followers**: Dapatkan 50 followers
- 🌳 **100 Followers**: Dapatkan 100 followers
- 🏆 **500 Followers**: Dapatkan 500 followers

**Cara Mendapatkan**:

1. Buat series yang menarik
2. Promosikan series kamu
3. Reader akan follow kamu
4. Badge otomatis diberikan saat mencapai milestone

**Trigger**: Otomatis saat ada reader yang follow
**Location**: `FollowController@toggle`

---

### 2. First AU Badge

**Cara Mendapatkan**:

1. Switch role ke Author
2. Buat series pertama kamu
3. Badge otomatis diberikan

**Trigger**: Otomatis saat create series pertama
**Location**: `SeriesController@store`

---

## 📱 Cara Melihat Badge Collection

### Di Profile

1. Login sebagai Reader/Author
2. Buka Profile (tab paling kanan)
3. Scroll ke bawah
4. Lihat section "Achievements"
5. Badge yang sudah didapat akan ditampilkan dengan warna
6. Tap badge untuk melihat detail

### Di Badge Collection Screen

1. Login sebagai Reader/Author
2. Buka Profile
3. Tap "Badge Collection" di menu
4. Lihat semua badge (earned & locked)
5. Filter by category: All, Reading, Social, Creator, Special
6. Tap badge untuk detail lengkap

---

## 🔧 Technical Implementation

### Backend

**Badge Service**: `backend/app/Services/BadgeService.php`

**Methods**:

- `checkAndAwardBadges(User $user)`: Check all applicable badges
- `checkReadingBadges(User $user)`: Check reading milestones
- `checkFollowBadges(User $user)`: Check follow milestones
- `checkFirstCommentBadge(User $user)`: Check first comment
- `checkFirstBookmarkBadge(User $user)`: Check first bookmark
- `awardBadge(User $user, string $badgeKey)`: Award specific badge

**Triggers**:

- Reading complete → `ReadingController@updateProgress`
- Follow author → `FollowController@toggle`
- First comment → `CommentController@store`
- First bookmark → `BookmarkController@toggle`
- Unlock episode → `EpisodeUnlockController@unlock`
- Create series → `SeriesController@store`

### Frontend

**Badge Collection Screen**: `frontend/lib/features/reader/screens/badge_collection_screen.dart`

**Features**:

- Stats summary (earned, locked, total)
- Progress bar
- Category filter
- Grid view (earned & locked)
- Badge detail modal
- Pull to refresh

---

## 🎯 Badge Categories

### Reading

- Read 10/50/100 Chapters
- First Comment
- First Bookmark

### Social

- Follow 5/20 Authors
- (Future: Like 50 Series, etc.)

### Creator (Author only)

- First AU
- 10/50/100/500 Followers

### Special

- Spending badges (100/500/1000 coins)
- Event badges (future)
- Limited edition badges (future)

---

## 🔔 Notifications

Saat mendapat badge baru:

1. Notifikasi otomatis dikirim
2. Title: "Badge Baru! 🏆"
3. Body: "Kamu mendapatkan badge [Badge Name]"
4. Tap notifikasi untuk lihat detail badge

**Location**: `BadgeService@notifyBadgeEarned`

---

## 📊 Badge Data Structure

### Database Table: `badges`

```sql
- id: bigint
- key: string (unique identifier)
- name: string (display name)
- description: text
- icon: string (emoji)
- color: string (hex color)
- category: enum (reading, social, creator, special)
- condition_type: enum (followers, spend, manual)
- condition_value: integer
- created_at, updated_at
```

### Pivot Table: `user_badges`

```sql
- user_id: bigint
- badge_id: bigint
- earned_at: timestamp
- is_pinned: boolean
```

---

## 🎮 Testing Badge System

### Test as Reader

1. **Reading Badge**:

   ```
   - Read 10 different episodes to completion
   - Check badge collection
   - Should see "Read 10 Chapters" badge
   ```

2. **Follow Badge**:

   ```
   - Follow 5 different authors
   - Check badge collection
   - Should see "Follow 5 Authors" badge
   ```

3. **First Comment Badge**:

   ```
   - Write your first comment on any episode
   - Check badge collection
   - Should see "First Comment" badge
   ```

4. **First Bookmark Badge**:

   ```
   - Bookmark any series
   - Check badge collection
   - Should see "First Bookmark" badge
   ```

5. **Spending Badge**:
   ```
   - Unlock premium episodes until total spending >= 100 coins
   - Check badge collection
   - Should see "Spend 100 Coins" badge
   ```

### Test as Author

1. **First AU Badge**:

   ```
   - Switch to Author role
   - Create your first series
   - Check badge collection
   - Should see "First AU" badge
   ```

2. **Follower Badge**:
   ```
   - Get 10 followers (ask friends to follow)
   - Check badge collection
   - Should see "10 Followers" badge
   ```

---

## 🐛 Troubleshooting

### Badge tidak muncul setelah mencapai milestone

**Possible Causes**:

1. Badge belum di-seed ke database
2. Condition tidak match
3. Badge sudah dimiliki sebelumnya

**Solution**:

```bash
# Check if badges exist in database
php artisan tinker
Badge::all();

# Re-seed badges if needed
php artisan db:seed --class=BadgeSeeder

# Manually check user badges
$user = User::find(1);
$user->badges;
```

### Badge tidak otomatis diberikan

**Check**:

1. Pastikan BadgeService dipanggil di controller
2. Check log untuk error
3. Verify condition_type dan condition_value di database

**Debug**:

```php
// In controller
\Log::info('Checking badges for user: ' . $user->id);
$badges = \App\Services\BadgeService::checkReadingBadges($user);
\Log::info('New badges awarded: ' . count($badges));
```

---

## 🚀 Future Enhancements

### Planned Features

- [ ] Badge rarity system (common, rare, epic, legendary)
- [ ] Badge showcase on profile (pin up to 3 badges)
- [ ] Badge leaderboard
- [ ] Seasonal/event badges
- [ ] Badge trading system
- [ ] Badge rewards (coins, XP bonus)
- [ ] Achievement progress tracking
- [ ] Badge collections (complete sets for bonus)

### Potential New Badges

- **Binge Reader**: Read 10 episodes in one day
- **Night Owl**: Read 50 episodes after midnight
- **Loyal Fan**: Read all episodes of 5 different series
- **Generous Supporter**: Send 10 tips to authors
- **Social Butterfly**: Get 100 likes on your comments
- **Early Bird**: Read new episodes within 1 hour of publish

---

## 📝 Summary

**Badge System Status**: ✅ Fully Functional

**Reader Badges Available**:

- Reading: 3 badges (10, 50, 100 chapters)
- Social: 2 badges (5, 20 follows)
- First Actions: 2 badges (comment, bookmark)
- Spending: 3 badges (100, 500, 1000 coins)

**Author Badges Available**:

- Creator: 1 badge (first AU)
- Followers: 4 badges (10, 50, 100, 500 followers)

**Total**: 15+ badges available

**How to Get Badges**: Otomatis diberikan saat mencapai milestone
**How to View**: Profile → Badge Collection
**Notifications**: Ya, otomatis saat dapat badge baru

---

**Last Updated**: 2026-04-26
**Status**: ✅ COMPLETE & WORKING
**Feature**: Badge System for Readers & Authors
