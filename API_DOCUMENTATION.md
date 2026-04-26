# AU Reader V2 - API Documentation

## Base URL
```
http://localhost:8000/api/v1
```

## Authentication
Semua endpoint yang memerlukan autentikasi menggunakan Laravel Sanctum dengan Bearer token.

**Header**:
```
Authorization: Bearer {token}
Accept: application/json
Content-Type: application/json
```

---

## 📚 Table of Contents
1. [Authentication](#authentication-endpoints)
2. [Notifications](#notification-endpoints)
3. [Wallet](#wallet-endpoints)
4. [Missions](#mission-endpoints)
5. [Leaderboard](#leaderboard-endpoints)
6. [Comments](#comment-endpoints)
7. [Reader Endpoints](#reader-endpoints)
8. [Author Endpoints](#author-endpoints)

---

## Authentication Endpoints

### Register
```http
POST /auth/register
```

**Body**:
```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "password123",
  "password_confirmation": "password123",
  "role": "reader"
}
```

**Response** (201):
```json
{
  "message": "Registrasi berhasil",
  "user": {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com",
    "role": "reader"
  },
  "token": "1|abc123..."
}
```

### Login
```http
POST /auth/login
```

**Body**:
```json
{
  "email": "john@example.com",
  "password": "password123"
}
```

**Response** (200):
```json
{
  "message": "Login berhasil",
  "user": {
    "id": 1,
    "name": "John Doe",
    "role": "reader"
  },
  "token": "2|xyz789..."
}
```

### Get Current User
```http
GET /auth/me
```

**Response** (200):
```json
{
  "id": 1,
  "name": "John Doe",
  "email": "john@example.com",
  "role": "reader",
  "coins": 100,
  "xp": {
    "total_xp": 150,
    "level": 1,
    "next_level_xp": 200
  }
}
```

### Update Profile
```http
PUT /auth/profile
```

**Body**:
```json
{
  "name": "John Updated",
  "bio": "My bio",
  "avatar_url": "avatars/avatar.jpg"
}
```

### Switch Role
```http
POST /auth/switch-role
```

**Body**:
```json
{
  "role": "author"
}
```

### Logout
```http
POST /auth/logout
```

---

## Notification Endpoints

### Get Notifications
```http
GET /notifications?role=reader&page=1
```

**Response** (200):
```json
{
  "current_page": 1,
  "data": [
    {
      "id": "uuid-123",
      "type": "new_episode",
      "title": "Episode Baru!",
      "body": "Series favorit kamu ada episode baru",
      "is_read": false,
      "created_at": "2026-04-24T10:00:00Z"
    }
  ],
  "total": 10,
  "unread_count": 5
}
```

### Get Unread Count
```http
GET /notifications/unread-count?role=reader
```

**Response** (200):
```json
{
  "count": 5
}
```

### Mark as Read
```http
POST /notifications/{id}/read
```

### Mark All as Read
```http
POST /notifications/read-all
```

**Body**:
```json
{
  "role": "reader"
}
```

---

## Wallet Endpoints

### Get Wallet Info
```http
GET /wallet
```

**Response** (200):
```json
{
  "coins": 100,
  "lifetime_spend": 50,
  "supporter_level": null,
  "transactions": [
    {
      "id": 1,
      "type": "daily_reward",
      "amount": 10,
      "description": "Daily login reward",
      "created_at": "2026-04-24T10:00:00Z"
    }
  ]
}
```

### Get Daily Status
```http
GET /wallet/daily-status
```

**Response** (200):
```json
{
  "streak": 3,
  "claimed_today": true,
  "next_reward_xp": 30,
  "next_reward_coins": 0,
  "has_received_coin_bonus": false,
  "week_days": [
    {
      "date": "2026-04-24",
      "day": "Fri",
      "claimed": true
    }
  ]
}
```

### Claim Daily Reward (Reader Only)
```http
POST /wallet/daily-reward
```

**Response** (200):
```json
{
  "message": "Daily reward claimed!",
  "xp_earned": 30,
  "coins_earned": 0,
  "streak": 3
}
```

### Send Tip
```http
POST /wallet/tip
```

**Body**:
```json
{
  "author_id": 2,
  "series_id": 1,
  "amount": 50
}
```

### Get Badges
```http
GET /wallet/badges
```

### Get Tier Progress
```http
GET /wallet/tier-progress
```

---

## Mission Endpoints

### Get Missions (Reader Only)
```http
GET /missions
```

**Response** (200):
```json
{
  "daily": [
    {
      "id": 1,
      "code": "daily_login",
      "title": "Login Harian",
      "description": "Login ke aplikasi",
      "type": "daily",
      "target": 1,
      "xp_reward": 10,
      "coin_reward": 0,
      "progress": 1,
      "is_completed": true,
      "is_claimed": false
    }
  ],
  "weekly": [],
  "one_time": []
}
```

### Claim Mission (Reader Only)
```http
POST /missions/{mission}/claim
```

**Response** (200):
```json
{
  "message": "Mission claimed!",
  "xp_earned": 10,
  "coins_earned": 0,
  "total_xp": 160,
  "level": 1
}
```

---

## Leaderboard Endpoints

### Get Overview
```http
GET /leaderboard/overview
```

**Response** (200):
```json
{
  "season": {
    "id": 1,
    "name": "Season 1",
    "start_date": "2026-04-01",
    "end_date": "2026-06-30"
  },
  "user_global_rank": {
    "rank": 10,
    "xp": 150
  },
  "user_supporter_rank": {
    "rank": 5,
    "total_spent": 100
  }
}
```

### Get Top XP
```http
GET /leaderboard/top-xp?limit=10
```

### Get Top Supporters
```http
GET /leaderboard/top-supporters?limit=10
```

### Get Top Authors
```http
GET /leaderboard/top-authors?limit=10
```

### Get Author Supporters
```http
GET /leaderboard/author/{author}/supporters?limit=10
```

---

## Comment Endpoints

### Get Comments
```http
GET /episodes/{episode}/comments?page=1
```

**Response** (200):
```json
{
  "current_page": 1,
  "data": [
    {
      "id": 1,
      "user": {
        "id": 1,
        "name": "John Doe",
        "avatar_url": null
      },
      "body": "Great episode!",
      "likes_count": 5,
      "is_liked": false,
      "created_at": "2026-04-24T10:00:00Z",
      "replies": []
    }
  ]
}
```

### Post Comment
```http
POST /episodes/{episode}/comments
```

**Body**:
```json
{
  "body": "This is my comment",
  "parent_id": null
}
```

### Toggle Like Comment
```http
POST /comments/{comment}/like
```

### Delete Comment
```http
DELETE /comments/{comment}
```

---

## Reader Endpoints

### Get FYP (For You Page)
```http
GET /reader/fyp
```

**Response** (200):
```json
{
  "featured": [],
  "continue_reading": [],
  "trending": [],
  "recommended": [],
  "latest": [],
  "new_releases": [],
  "genres": []
}
```

### Search
```http
GET /reader/search?q=keyword&page=1
```

**Response** (200):
```json
{
  "users": [],
  "data": [
    {
      "id": 1,
      "title": "My Series",
      "slug": "my-series",
      "cover_url": "covers/cover.jpg",
      "author": {
        "id": 2,
        "name": "Author Name"
      }
    }
  ],
  "total": 10
}
```

### Get My Profile
```http
GET /reader/profile
```

### Get Public Profile
```http
GET /reader/profile/{user}
```

### Get Author Profile
```http
GET /reader/author/{user}/profile
```

### Get Bookmarks
```http
GET /reader/bookmarks?page=1
```

### Toggle Bookmark
```http
POST /reader/bookmarks/{series}/toggle
```

### Check Bookmark
```http
GET /reader/bookmarks/{series}/check
```

**Response** (200):
```json
{
  "bookmarked": true
}
```

### Get Reading History
```http
GET /reader/history?page=1
```

### Get Series Detail
```http
GET /reader/series/{series}
```

**Response** (200):
```json
{
  "id": 1,
  "title": "My Series",
  "synopsis": "Description",
  "cover_url": "covers/cover.jpg",
  "author": {
    "id": 2,
    "name": "Author Name"
  },
  "episodes": [
    {
      "id": 1,
      "title": "Episode 1",
      "episode_number": 1,
      "is_premium": false,
      "coin_price": 0,
      "is_unlocked": true
    }
  ],
  "is_bookmarked": false,
  "is_liked": false
}
```

### Read Episode
```http
GET /reader/series/{series}/episodes/{episode}
```

**Response** (200):
```json
{
  "id": 1,
  "title": "Episode 1",
  "episode_number": 1,
  "is_premium": false,
  "coin_price": 0,
  "is_unlocked": true,
  "pages": [
    {
      "id": 1,
      "image_path": "episodes/pages/page1.jpg",
      "page_order": 1
    }
  ],
  "prev_episode": null,
  "next_episode": {
    "id": 2,
    "episode_number": 2
  }
}
```

### Update Reading Progress
```http
POST /reader/series/{series}/episodes/{episode}/progress
```

**Body**:
```json
{
  "progress": 75
}
```

### Toggle Series Like
```http
POST /reader/series/{series}/like
```

### Toggle Episode Like
```http
POST /reader/series/{series}/episodes/{episode}/like
```

### Get Unlocked Episodes
```http
GET /reader/episodes/unlocked?page=1
```

### Unlock Episode
```http
POST /reader/episodes/{episode}/unlock
```

**Response** (200):
```json
{
  "message": "Episode berhasil di-unlock",
  "remaining_coins": 50
}
```

### Get Collections
```http
GET /reader/collections?page=1
```

### Create Collection
```http
POST /reader/collections
```

**Body**:
```json
{
  "name": "My Favorites",
  "description": "Collection of my favorite series",
  "is_public": true
}
```

### Get Collection Detail
```http
GET /reader/collections/{collection}
```

### Update Collection
```http
PUT /reader/collections/{collection}
```

### Delete Collection
```http
DELETE /reader/collections/{collection}
```

### Add Series to Collection
```http
POST /reader/collections/{collection}/series
```

**Body**:
```json
{
  "series_id": 1
}
```

### Remove Series from Collection
```http
DELETE /reader/collections/{collection}/series/{series}
```

### Get My Comments
```http
GET /reader/my-comments?page=1
```

### Get Following
```http
GET /reader/following?page=1
```

### Get Followers
```http
GET /reader/followers?page=1
```

### Toggle Follow
```http
POST /reader/follow/{user}/toggle
```

### Check Follow Status
```http
GET /reader/follow/{user}/check
```

---

## Author Endpoints

### Get Dashboard
```http
GET /author/dashboard
```

**Response** (200):
```json
{
  "total_series": 5,
  "total_episodes": 20,
  "total_views": 1000,
  "total_likes": 50,
  "followers": 100,
  "recent_series": []
}
```

### Get Series Counts
```http
GET /author/series-counts
```

### Get Series List
```http
GET /author/series?page=1
```

### Create Series
```http
POST /author/series
```

**Body**:
```json
{
  "title": "My New Series",
  "synopsis": "Description",
  "genre": "fantasy",
  "age_rating": "all",
  "cover_url": "covers/cover.jpg"
}
```

### Update Series
```http
PUT /author/series/{series}
```

### Delete Series
```http
DELETE /author/series/{series}
```

### Publish Series
```http
POST /author/series/{series}/publish
```

### Get Episodes
```http
GET /author/series/{series}/episodes
```

### Create Episode
```http
POST /author/series/{series}/episodes
```

**Body**:
```json
{
  "title": "Episode 1",
  "episode_number": 1,
  "is_premium": false,
  "coin_price": 0
}
```

### Update Episode
```http
PATCH /author/episodes/{episode}
```

### Publish Episode
```http
POST /author/episodes/{episode}/publish
```

### Delete Episode
```http
DELETE /author/episodes/{episode}
```

### Generate Signed URL for Upload
```http
POST /author/uploads/signed-url
```

**Body**:
```json
{
  "filename": "page1.jpg",
  "type": "image/jpeg"
}
```

**Response** (200):
```json
{
  "upload_url": "https://r2.example.com/...",
  "path": "episodes/pages/unique_page1.jpg",
  "public_url": "https://cdn.example.com/episodes/pages/unique_page1.jpg"
}
```

### Get Pages
```http
GET /author/episodes/{episode}/pages
```

### Store Page Metadata
```http
POST /author/episodes/{episode}/pages
```

**Body**:
```json
{
  "image_path": "episodes/pages/page1.jpg",
  "width": 1200,
  "height": 1600,
  "file_size": 524288
}
```

### Replace Page
```http
PUT /author/pages/{page}
```

**Body**:
```json
{
  "image_path": "episodes/pages/new_page.jpg",
  "width": 1200,
  "height": 1600,
  "file_size": 524288
}
```

### Reorder Pages
```http
PATCH /author/episodes/{episode}/reorder
```

**Body**:
```json
{
  "pages": [
    {
      "id": 1,
      "order": 2
    },
    {
      "id": 2,
      "order": 1
    }
  ]
}
```

### Delete Page
```http
DELETE /author/pages/{page}
```

### Get Analytics Overview
```http
GET /author/analytics/overview
```

**Response** (200):
```json
{
  "total_views": 1000,
  "total_likes": 50,
  "followers": 100,
  "total_series": 5,
  "total_episodes": 20,
  "engagement_rate": 5.0,
  "author_tier": "bronze",
  "tier_progress": {}
}
```

### Get Analytics Trend
```http
GET /author/analytics/trend?days=7
```

**Response** (200):
```json
{
  "labels": ["2026-04-18", "2026-04-19", "2026-04-20"],
  "views": [10, 20, 30]
}
```

### Get Top Series
```http
GET /author/analytics/top-series?limit=5
```

### Get Top Episodes
```http
GET /author/analytics/top-episodes?limit=5
```

---

## Error Responses

### Validation Error (422)
```json
{
  "message": "The given data was invalid.",
  "errors": {
    "email": ["Email sudah terdaftar."],
    "password": ["Password minimal 8 karakter."]
  }
}
```

### Unauthorized (401)
```json
{
  "message": "Unauthenticated."
}
```

### Forbidden (403)
```json
{
  "message": "Anda tidak memiliki akses."
}
```

### Not Found (404)
```json
{
  "message": "Resource tidak ditemukan."
}
```

### Server Error (500)
```json
{
  "message": "Terjadi kesalahan server.",
  "error": "Error details..."
}
```

---

## Rate Limiting

### Global Rate Limit
- 60 requests per minute per IP

### Specific Endpoints
- Login: 5 requests per minute
- Signed URL: 30 requests per minute
- Comments: 10 per day per user
- Comment Likes: 30 per day per user
- Tips: 20 per day per user

---

## Pagination

Semua endpoint yang mengembalikan list data menggunakan pagination:

**Query Parameters**:
- `page`: Page number (default: 1)
- `per_page`: Items per page (default: 20, max: 100)

**Response Structure**:
```json
{
  "current_page": 1,
  "data": [],
  "first_page_url": "http://...",
  "from": 1,
  "last_page": 5,
  "last_page_url": "http://...",
  "next_page_url": "http://...",
  "path": "http://...",
  "per_page": 20,
  "prev_page_url": null,
  "to": 20,
  "total": 100
}
```

---

## Testing

Gunakan file `API_TEST_GUIDE.md` untuk panduan testing API dengan contoh request/response lengkap.

**Last Updated**: 2026-04-24
