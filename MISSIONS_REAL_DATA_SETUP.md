# Missions Screen - Real Data Setup Guide

## Status: READY FOR REAL DATA

## What Changed

✅ Removed dummy data fallback
✅ Now uses ONLY real data from backend API
✅ Better error handling with informative messages
✅ Comprehensive debug logging

## Backend Setup (REQUIRED)

### Step 1: Ensure Backend is Running

```bash
cd backend
php artisan serve
```

Backend should be running on `http://localhost:8000`

### Step 2: Seed Missions to Database

```bash
cd backend
php artisan db:seed --class=MissionSeeder
```

This will create 17 missions:

- 4 Daily missions
- 5 Weekly missions
- 8 Achievement missions (once)

### Step 3: Verify Missions Exist

```bash
cd backend
php test-missions-endpoint.php
```

You should see:

```
✅ Testing with user: Demo Reader Updated (ID: 1, Role: reader)
📊 Missions Count: 17
✅ Missions loaded successfully!
```

## Frontend Setup

### Step 1: Clean Build

```bash
cd frontend
flutter clean
flutter pub get
```

### Step 2: Run the App

```bash
flutter run
```

### Step 3: Test Missions Screen

1. Login as **READER** (not Author)
2. Go to Home screen
3. Tap the **star icon (⭐)** in the top right
4. Missions screen should load with 3 tabs

## Expected Behavior

### If Everything Works ✅

You should see:

**Daily Tab** (4 missions):

- Daily Login (10 XP + 5 Coins)
- Read 3 Episodes (15 XP + 10 Coins)
- Leave 2 Comments (10 XP + 5 Coins)
- Like 5 Episodes (10 XP + 5 Coins)

**Weekly Tab** (5 missions):

- Weekly Reader: Read 15 episodes (50 XP + 30 Coins)
- Active Commenter: 10 comments (40 XP + 25 Coins)
- Social Networker: Follow 3 authors (30 XP + 20 Coins)
- Collector: Bookmark 5 series (25 XP + 15 Coins)
- Consistency King: Login 7 days straight (100 XP + 50 Coins)

**Achievements Tab** (8 missions):

- First Read (20 XP + 10 Coins)
- First Comment (15 XP + 10 Coins)
- First Follow (15 XP + 10 Coins)
- First Bookmark (15 XP + 10 Coins)
- Avid Reader: 50 episodes (100 XP + 50 Coins)
- Bookworm: 100 episodes (200 XP + 100 Coins)
- Social Butterfly: Follow 10 authors (50 XP + 30 Coins)
- Supporter: Spend 100 coins (50 XP)

### If Screen is Empty ❌

Check console output for debug logs:

```
=== MISSIONS DEBUG START ===
Fetching missions from: missions
Response success: true/false
Response statusCode: 200/403/401/500
Response message: ...
Response data: {...}
```

## Troubleshooting

### Problem 1: Screen Shows Error

**Symptoms**: Error screen with "Failed to Load Missions"

**Possible Causes**:

1. Backend not running
2. Logged in as Author (not Reader)
3. Network connection issue
4. API endpoint misconfigured

**Solutions**:

```bash
# Check backend is running
cd backend
php artisan serve

# Verify you're logged in as Reader
# In app: Profile → Check role badge

# Check API base URL
# File: frontend/lib/core/constants/api_constants.dart
# Should be: http://localhost:8000/api/v1 (or your backend URL)
```

### Problem 2: Screen Shows Empty Tabs

**Symptoms**: Tabs load but show "No missions available"

**Possible Causes**:

1. Missions not seeded to database
2. API returns empty array
3. Response structure mismatch

**Solutions**:

```bash
# Re-seed missions
cd backend
php artisan db:seed --class=MissionSeeder

# Test API directly
php test-missions-endpoint.php

# Check console logs in Flutter
# Look for: "Daily missions: 0" (should be 4)
```

### Problem 3: 403 Forbidden

**Symptoms**: Console shows "Response statusCode: 403"

**Cause**: Logged in as Author, not Reader

**Solution**: Switch to Reader role in the app

- Go to Profile
- Tap "Switch to Reader" (if you're Author)
- Or logout and login as Reader

### Problem 4: 401 Unauthorized

**Symptoms**: Console shows "Response statusCode: 401"

**Cause**: Not authenticated or token expired

**Solution**:

- Logout and login again
- Check if token is being sent in API requests

### Problem 5: Network Error

**Symptoms**: Console shows "SocketException" or "Failed host lookup"

**Cause**: Backend URL is wrong or backend not running

**Solution**:

```bash
# Check backend is running
cd backend
php artisan serve

# Verify API base URL in frontend
# File: frontend/lib/core/constants/api_constants.dart
```

## Debug Console Output

When missions screen loads, you should see:

```
=== MISSIONS DEBUG START ===
Fetching missions from: missions
Response success: true
Response statusCode: 200
Response message: Success
Response data type: _Map<String, dynamic>
Response data: {success: true, missions: [{id: 1, name: Daily Login, ...}, ...]}
Found 17 missions in data.missions
Daily missions: 4
Weekly missions: 5
Once missions: 8
State updated successfully
=== MISSIONS DEBUG END ===
```

## API Endpoint Details

### Request

```
GET /api/v1/missions
Headers:
  Authorization: Bearer {token}
  Accept: application/json
```

### Response (Success)

```json
{
  "success": true,
  "missions": [
    {
      "id": 1,
      "code": "daily_login",
      "name": "Daily Login",
      "description": "Login ke aplikasi hari ini",
      "type": "daily",
      "xp_reward": 10,
      "coin_reward": 5,
      "target_count": 1,
      "progress": 0,
      "is_completed": false,
      "is_claimed": false,
      "can_claim": false
    },
    ...
  ]
}
```

### Response (Error - Author)

```json
{
  "message": "Fitur Gamifikasi hanya tersedia untuk Reader. Silakan switch ke Reader terlebih dahulu."
}
```

Status Code: 403

## Mission Progress Tracking

Missions automatically track progress when you:

- **Login**: Updates `daily_login` mission
- **Read Episode**: Updates read-related missions
- **Comment**: Updates comment-related missions
- **Like**: Updates like-related missions
- **Follow**: Updates follow-related missions
- **Bookmark**: Updates bookmark-related missions
- **Spend Coins**: Updates spending-related missions

Progress is tracked in `user_missions` table.

## Claiming Rewards

When a mission is completed (`can_claim: true`):

1. Tap the green "Claim" button
2. API call: `POST /api/v1/missions/{id}/claim`
3. Rewards are added to user's XP and Coins
4. Mission status changes to "Claimed"
5. Screen refreshes automatically

## Files Modified

1. `frontend/lib/features/reader/screens/missions_screen.dart`
   - Removed dummy data
   - Added proper error handling
   - Enhanced debug logging

2. `backend/database/seeders/MissionSeeder.php`
   - Already exists with 17 missions

3. `backend/app/Services/MissionService.php`
   - Already working correctly

4. `backend/app/Http/Controllers/Api/V1/Gamification/MissionController.php`
   - Already working correctly

## Testing Checklist

- [ ] Backend is running (`php artisan serve`)
- [ ] Missions are seeded (`php artisan db:seed --class=MissionSeeder`)
- [ ] Test endpoint works (`php test-missions-endpoint.php`)
- [ ] Frontend is built (`flutter clean && flutter pub get`)
- [ ] App is running (`flutter run`)
- [ ] Logged in as Reader (not Author)
- [ ] Missions screen shows 3 tabs
- [ ] Daily tab shows 4 missions
- [ ] Weekly tab shows 5 missions
- [ ] Achievements tab shows 8 missions
- [ ] Progress bars are visible
- [ ] XP and Coin rewards are displayed
- [ ] Pull to refresh works
- [ ] Help button works

## Next Steps

1. Run backend: `cd backend && php artisan serve`
2. Seed missions: `php artisan db:seed --class=MissionSeeder`
3. Run frontend: `cd frontend && flutter run`
4. Login as Reader
5. Open missions screen
6. Share console output if there are issues

---

**Last Updated**: 2026-04-26
**Status**: ✅ READY FOR REAL DATA
**Backend Required**: YES
**Dummy Data**: REMOVED
