# AU Reader API Testing Guide

## Setup

1. Pastikan backend sudah running:
```bash
cd backend
php artisan serve
```

2. Pastikan database sudah di-migrate dan seed:
```bash
php artisan migrate:fresh --seed
```

---

## Test Endpoints

### 1. Public Endpoints

#### Get Genres
```bash
curl http://localhost:8000/api/v1/public/genres
```

Expected: List of genres

---

### 2. Authentication

#### Register (Reader)
```bash
curl -X POST http://localhost:8000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Reader",
    "email": "reader@test.com",
    "password": "Password123",
    "password_confirmation": "Password123",
    "role": "reader"
  }'
```

Expected: User object + token

#### Register (Author)
```bash
curl -X POST http://localhost:8000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Author",
    "email": "author@test.com",
    "password": "Password123",
    "password_confirmation": "Password123",
    "role": "author",
    "pen_name": "Author Pen Name",
    "bio": "This is my author bio"
  }'
```

Expected: User object + token

#### Login
```bash
curl -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "reader@test.com",
    "password": "Password123"
  }'
```

Expected: User object + token
Save the token for next requests!

#### Get Current User
```bash
curl http://localhost:8000/api/v1/auth/me \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

Expected: User profile with all details

---

### 3. Mission System (Reader Only)

#### Get All Missions
```bash
curl http://localhost:8000/api/v1/missions \
  -H "Authorization: Bearer YOUR_READER_TOKEN"
```

Expected: List of missions with progress

#### Claim Mission Reward
```bash
curl -X POST http://localhost:8000/api/v1/missions/1/claim \
  -H "Authorization: Bearer YOUR_READER_TOKEN"
```

Expected: Success message with XP and coin rewards

---

### 4. Wallet

#### Get Wallet Info
```bash
curl http://localhost:8000/api/v1/wallet \
  -H "Authorization: Bearer YOUR_TOKEN"
```

Expected: Wallet balance and transaction history

#### Daily Status
```bash
curl http://localhost:8000/api/v1/wallet/daily-status \
  -H "Authorization: Bearer YOUR_TOKEN"
```

Expected: Daily reward claim status

#### Claim Daily Reward (Reader Only)
```bash
curl -X POST http://localhost:8000/api/v1/wallet/daily-reward \
  -H "Authorization: Bearer YOUR_READER_TOKEN"
```

Expected: Coins awarded

---

### 5. Leaderboard

#### Overview
```bash
curl http://localhost:8000/api/v1/leaderboard/overview \
  -H "Authorization: Bearer YOUR_TOKEN"
```

Expected: Leaderboard overview

#### Top XP
```bash
curl http://localhost:8000/api/v1/leaderboard/top-xp \
  -H "Authorization: Bearer YOUR_TOKEN"
```

Expected: Top 50 users by XP

#### Top Supporters
```bash
curl http://localhost:8000/api/v1/leaderboard/top-supporters \
  -H "Authorization: Bearer YOUR_TOKEN"
```

Expected: Top supporters by coins spent

#### Top Authors
```bash
curl http://localhost:8000/api/v1/leaderboard/top-authors \
  -H "Authorization: Bearer YOUR_TOKEN"
```

Expected: Top authors by earnings

---

### 6. Reader Features (Reader Role Only)

#### FYP (For You Page)
```bash
curl http://localhost:8000/api/v1/reader/fyp \
  -H "Authorization: Bearer YOUR_READER_TOKEN"
```

Expected: Recommended series

#### Search
```bash
curl "http://localhost:8000/api/v1/reader/search?q=test" \
  -H "Authorization: Bearer YOUR_READER_TOKEN"
```

Expected: Search results

#### Get Bookmarks
```bash
curl http://localhost:8000/api/v1/reader/bookmarks \
  -H "Authorization: Bearer YOUR_READER_TOKEN"
```

Expected: List of bookmarked series

#### Reading History
```bash
curl http://localhost:8000/api/v1/reader/history \
  -H "Authorization: Bearer YOUR_READER_TOKEN"
```

Expected: Reading history

---

### 7. Author Features (Author Role Only)

#### Dashboard
```bash
curl http://localhost:8000/api/v1/author/dashboard \
  -H "Authorization: Bearer YOUR_AUTHOR_TOKEN"
```

Expected: Author dashboard stats

#### Get Series
```bash
curl http://localhost:8000/api/v1/author/series \
  -H "Authorization: Bearer YOUR_AUTHOR_TOKEN"
```

Expected: List of author's series

#### Create Series
```bash
curl -X POST http://localhost:8000/api/v1/author/series \
  -H "Authorization: Bearer YOUR_AUTHOR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Test Series",
    "synopsis": "This is a test series",
    "genre": "Romance",
    "age_rating": "all",
    "status": "draft"
  }'
```

Expected: Created series object

#### Analytics Overview
```bash
curl http://localhost:8000/api/v1/author/analytics/overview \
  -H "Authorization: Bearer YOUR_AUTHOR_TOKEN"
```

Expected: Analytics data

---

## Testing Mission Tracking

### Test Daily Login Mission
1. Login as reader (mission should auto-track)
2. Check missions endpoint - daily_login should have progress = 1
3. If completed, claim reward

### Test Reading Mission
1. As reader, read an episode to 100% progress
2. Check missions endpoint - daily_read_3 should increment
3. Read 3 episodes total
4. Claim reward when completed

### Test Comment Mission
1. As reader, post a comment on an episode
2. Check missions endpoint - daily_comment_2 should increment
3. Post 2 comments total
4. Claim reward when completed

### Test Follow Mission
1. As reader, follow an author
2. Check missions endpoint - weekly_follow_3 should increment
3. Follow 3 authors total
4. Claim reward when completed

### Test Bookmark Mission
1. As reader, bookmark a series
2. Check missions endpoint - weekly_bookmark_5 should increment
3. Bookmark 5 series total
4. Claim reward when completed

---

## Common Issues

### Issue: "Unauthenticated"
Solution: Make sure you include the Bearer token in Authorization header

### Issue: "This action is unauthorized"
Solution: Check if you're using the correct role (reader/author) for the endpoint

### Issue: "Mission not found"
Solution: Make sure missions are seeded. Run `php artisan db:seed --class=MissionSeeder`

### Issue: "Validation failed"
Solution: Check the request body matches the expected format

---

## Database Reset

If you need to reset everything:
```bash
php artisan migrate:fresh --seed
```

This will:
1. Drop all tables
2. Run all migrations
3. Seed genres, badges, missions, supporter levels, and first season

---

**Last Updated**: 2026-04-24
