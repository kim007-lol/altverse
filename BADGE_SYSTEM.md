# Badge System Documentation

## Overview
Comprehensive badge system for AU Reader V2 with automatic badge awarding, notifications, and multiple badge types.

## Badge Types

### 1. Follower-Based Badges (Authors)
Automatically awarded based on follower count.

| Badge | Key | Followers Required | Color |
|-------|-----|-------------------|-------|
| Rising Author | `rising_author` | 100 | Bronze (#CD7F32) |
| Popular Author | `popular_author` | 1,000 | Silver (#C0C0C0) |
| Star Author | `star_author` | 10,000 | Gold (#FFD700) |
| Influencer Author | `influencer_author` | 50,000 | Purple (#9B59B6) |
| Legendary Author | `legendary_author` | 100,000 | Red (#E74C3C) |

**Trigger**: Automatically checked when a user follows/unfollows an author.

### 2. Spend-Based Badges (Readers)
Automatically awarded based on total coin spending (tips + episode unlocks).

| Badge | Key | Total Spend | Color |
|-------|-----|-------------|-------|
| Perak Supporter | `lifetime_perak` | 500 coins | Silver (#C0C0C0) |
| Emas Supporter | `lifetime_emas` | 1,000 coins | Gold (#FFD700) |
| Diamond Supporter | `lifetime_diamond` | 2,000 coins | Cyan (#00FFFF) |
| Platinum Supporter | `lifetime_platinum` | 5,000 coins | Platinum (#E5E4E2) |
| Legendary Supporter | `lifetime_legendary` | 10,000 coins | Magenta (#FF00FF) |

**Trigger**: Automatically checked when a user sends a tip or unlocks an episode.

### 3. Reading Badges (Readers)
Awarded based on reading completion count.

| Badge | Key | Episodes Read |
|-------|-----|---------------|
| Bookworm | `read_10_chapters` | 10 |
| Avid Reader | `read_50_chapters` | 50 |
| Scholar | `read_100_chapters` | 100 |

**Trigger**: Automatically checked when a user completes reading an episode (progress >= 100%).

### 4. Follow Badges (Readers)
Awarded based on number of authors followed.

| Badge | Key | Authors Followed |
|-------|-----|------------------|
| Social Butterfly | `follow_5_authors` | 5 |
| Networker | `follow_20_authors` | 20 |

**Trigger**: Automatically checked when a user follows an author.

### 5. Manual/Event Badges
Awarded on specific first-time events.

| Badge | Key | Trigger Event |
|-------|-----|---------------|
| Debut Author | `first_au` | Create first series |
| Vocal Reader | `first_comment` | Post first comment |
| Collector | `first_bookmark` | Add first bookmark |
| Rising Star | `au_1000_views` | Series reaches 1,000 views |
| Trending Author | `au_10000_views` | Series reaches 10,000 views |
| Influencer | `gain_100_followers` | Reach 100 followers |
| Storyteller | `complete_au` | Complete a series |
| Completionist | `finish_1_au` | Finish reading 1 series |
| Marathoner | `finish_10_au` | Finish reading 10 series |
| Consistent | `streak_7_days` | 7-day reading streak |

## BadgeService Methods

### `checkAndAwardBadges(User $user): array`
Main method that checks and awards all applicable badges for a user.
- Checks follower-based badges (for authors)
- Checks spend-based badges (for readers)
- Sends notifications for new badges
- Returns array of newly earned badges

**Usage**:
```php
$newBadges = BadgeService::checkAndAwardBadges($user);
```

### `awardBadge(User $user, string $badgeKey): ?Badge`
Award a specific badge by key (for manual/event badges).
- Returns the badge if newly awarded
- Returns null if badge doesn't exist or already earned
- Sends notification automatically

**Usage**:
```php
BadgeService::awardBadge($user, 'first_au');
```

### Specific Check Methods

#### `checkFirstAuBadge(User $user): void`
Check and award "first_au" badge for authors.

#### `checkFirstCommentBadge(User $user): void`
Check and award "first_comment" badge for readers.

#### `checkFirstBookmarkBadge(User $user): void`
Check and award "first_bookmark" badge for readers.

#### `checkReadingBadges(User $user): void`
Check and award reading milestone badges (10, 50, 100 chapters).

#### `checkFollowBadges(User $user): void`
Check and award follow milestone badges (5, 20 authors).

## Controller Integration

### FollowController
```php
// After follow/unfollow
BadgeService::checkAndAwardBadges($author); // Check follower badges for author
BadgeService::checkFollowBadges($reader);   // Check follow badges for reader
```

### SeriesController
```php
// After creating series
BadgeService::checkFirstAuBadge($user);
```

### CommentController
```php
// After posting comment
BadgeService::checkFirstCommentBadge($user);
```

### BookmarkController
```php
// After adding bookmark
BadgeService::checkFirstBookmarkBadge($user);
```

### ReadingController
```php
// After completing episode
BadgeService::checkReadingBadges($user);
```

### WalletController
```php
// After sending tip
BadgeService::checkAndAwardBadges($user);
```

### EpisodeUnlockController
```php
// After unlocking episode
BadgeService::checkAndAwardBadges($user);
```

## Notifications

When a badge is earned, a notification is automatically sent:

**Type**: `badge_earned`  
**Title**: "Badge Baru! 🏆"  
**Body**: "Kamu mendapatkan badge \"{badge_name}\""  
**Data**:
```json
{
  "badge_id": 1,
  "badge_key": "first_comment",
  "badge_name": "Vocal Reader"
}
```

## Database Schema

### badges table
```sql
- id (primary key)
- key (unique string)
- name (string)
- description (text)
- icon_url (nullable string)
- category (enum: reader, author)
- condition_type (nullable: followers, spend)
- condition_value (nullable integer)
- color (nullable string, hex color)
- created_at, updated_at
```

### badge_user pivot table
```sql
- user_id (foreign key)
- badge_id (foreign key)
- earned_at (timestamp)
- is_pinned (boolean, default false)
```

## API Endpoints

### Get User Badges
```
GET /api/v1/wallet/badges
Authorization: Bearer {token}
```

**Response**:
```json
{
  "earned": [
    {
      "id": 9,
      "key": "first_comment",
      "name": "Vocal Reader",
      "description": "Komentar pertama",
      "category": "reader",
      "pivot": {
        "earned_at": "2026-04-24T15:53:49.000000Z"
      }
    }
  ],
  "all": [...]
}
```

### Pin Badge
```
POST /api/v1/users/badges/{badge}/pin
Authorization: Bearer {token}
```

## Testing

### Test Follower Badge
1. Create author account
2. Have multiple readers follow the author
3. Check if follower badges are awarded at milestones (100, 1000, etc)

### Test Spend Badge
1. Create reader account with coins
2. Send tips or unlock episodes
3. Check if spend badges are awarded at milestones (500, 1000, 2000, etc)

### Test First Comment Badge
1. Create new reader account
2. Post first comment
3. Check if "first_comment" badge is awarded
4. Check if notification is sent

### Test Reading Badge
1. Create reader account
2. Complete reading 10 episodes
3. Check if "read_10_chapters" badge is awarded

## Future Enhancements

- [ ] Badge showcase in profile
- [ ] Badge animation on earn (frontend)
- [ ] Badge rarity system
- [ ] Limited edition seasonal badges
- [ ] Badge trading/gifting
- [ ] Badge leaderboard
- [ ] Badge collections/sets with bonus rewards
- [ ] Custom badge icons
- [ ] Badge progress tracking UI

---

**Last Updated**: 2026-04-24  
**Status**: ✅ Complete
