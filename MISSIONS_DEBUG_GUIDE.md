# Missions Screen Debug Guide

## Status: READY FOR TESTING

## What We Fixed

### 1. Compilation Error ✅

**File**: `frontend/lib/features/reader/screens/home_screen.dart`
**Issue**: Missing `const` keyword in MissionsScreen constructor
**Fix**: Changed `MissionsScreen()` to `const MissionsScreen()`

### 2. Enhanced Debug Logging ✅

**File**: `frontend/lib/features/reader/screens/missions_screen.dart`
**Added**: Comprehensive debug logging to track API calls and responses

### 3. Response Structure Handling ✅

**File**: `frontend/lib/features/reader/screens/missions_screen.dart`
**Added**: Fallback handling for different API response structures

## How to Test

### Step 1: Run the App

```bash
cd frontend
flutter run
```

### Step 2: Navigate to Missions

1. Open the app on your Android device
2. Make sure you're logged in as a READER (not Author)
3. Tap the star icon (⭐) in the top right of the home screen
4. This will open the Missions screen

### Step 3: Check Console Output

Look for these debug messages in your terminal/console:

```
=== MISSIONS DEBUG START ===
Fetching missions from: missions
Response success: true/false
Response statusCode: 200
Response message: ...
Response data type: _Map<String, dynamic>
Response data: {success: true, missions: [...]}
Found X missions in data.missions
Daily missions: X
Weekly missions: X
Once missions: X
State updated successfully
=== MISSIONS DEBUG END ===
```

## What to Look For

### ✅ Success Case

If everything works, you should see:

- `Response success: true`
- `Response statusCode: 200`
- `Found X missions in data.missions` (where X > 0)
- Missions displayed in the app with 3 tabs

### ❌ Error Cases

#### Case 1: 403 Forbidden

```
Response success: false
Response statusCode: 403
Response message: Fitur Gamifikasi hanya tersedia untuk Reader...
```

**Cause**: You're logged in as Author
**Solution**: Switch to Reader role in the app

#### Case 2: 401 Unauthorized

```
Response success: false
Response statusCode: 401
```

**Cause**: Not authenticated or token expired
**Solution**: Log out and log back in

#### Case 3: Empty Missions

```
Response success: true
Found 0 missions in data.missions
Daily missions: 0
Weekly missions: 0
Once missions: 0
```

**Cause**: Database not seeded with missions
**Solution**: Run the mission seeder:

```bash
cd backend
php artisan db:seed --class=MissionSeeder
```

#### Case 4: Network Error

```
=== MISSIONS ERROR ===
Error: SocketException: Failed host lookup...
```

**Cause**: Backend not running or wrong URL
**Solution**:

1. Check if backend is running: `cd backend && php artisan serve`
2. Verify API base URL in `frontend/lib/core/constants/api_constants.dart`

#### Case 5: Unexpected Response Structure

```
ERROR: Unexpected response structure
Response data type: ...
Available keys: [...]
```

**Cause**: API response format doesn't match expectations
**Solution**: Share the complete debug output

## Backend Verification

If you want to test the backend directly:

### Test 1: Check if missions endpoint works

```bash
cd backend
php artisan tinker
```

Then run:

```php
$user = User::where('role', 'reader')->first();
$missions = app(\App\Services\MissionService::class)->getUserMissions($user);
dd($missions);
```

### Test 2: Check if missions are seeded

```bash
php artisan tinker
```

Then run:

```php
\App\Models\Mission::count();
// Should return 17 or more
```

### Test 3: Test API endpoint directly

Create a test file `backend/test-missions-api.php`:

```php
<?php
require __DIR__.'/vendor/autoload.php';

$app = require_once __DIR__.'/bootstrap/app.php';
$app->make(\Illuminate\Contracts\Console\Kernel::class)->bootstrap();

// Get a reader user
$user = \App\Models\User::where('role', 'reader')->first();

if (!$user) {
    echo "No reader user found!\n";
    exit(1);
}

// Create token
$token = $user->createToken('test')->plainTextToken;

// Make API request
$ch = curl_init('http://localhost:8000/api/v1/missions');
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Authorization: Bearer ' . $token,
    'Accept: application/json',
]);

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

echo "HTTP Code: $httpCode\n";
echo "Response: $response\n";
```

Run it:

```bash
php backend/test-missions-api.php
```

## Common Issues & Solutions

### Issue: "MissionsScreen not found"

**Solution**: Already fixed - make sure you pulled the latest changes

### Issue: Screen shows "Missions only available for Readers"

**Solution**: You're logged in as Author. Switch to Reader role

### Issue: Screen shows loading forever

**Solution**: Check console for errors. Likely a network issue or backend not running

### Issue: Screen shows empty tabs

**Solution**: Database not seeded. Run `php artisan db:seed --class=MissionSeeder`

## Files Modified

1. `frontend/lib/features/reader/screens/missions_screen.dart`
   - Added comprehensive debug logging
   - Added fallback for different response structures
   - Improved error handling

2. `frontend/lib/features/reader/screens/home_screen.dart`
   - Fixed const constructor call

## Next Steps

1. Run the app with `flutter run`
2. Navigate to Missions screen
3. Copy ALL console output between `=== MISSIONS DEBUG START ===` and `=== MISSIONS DEBUG END ===`
4. Share the output so we can identify the exact issue

## Expected Behavior

When working correctly:

- Missions screen shows 3 tabs: Daily, Weekly, Achievements
- Each tab shows missions with:
  - Mission name and description
  - Progress bar (X/Y completed)
  - XP and Coin rewards
  - Status: "In Progress", "Complete", "Claim", or "Claimed"
- Tapping "Claim" button awards rewards and updates the mission status
- Pull to refresh reloads missions

## Technical Details

### API Endpoint

- **URL**: `/api/v1/missions`
- **Method**: GET
- **Auth**: Bearer token required
- **Middleware**: `reader-only` (blocks Authors)

### Response Format

```json
{
  "success": true,
  "missions": [
    {
      "id": 1,
      "name": "First Steps",
      "description": "Read your first episode",
      "type": "once",
      "target_count": 1,
      "xp_reward": 50,
      "coin_reward": 10,
      "progress": 0,
      "is_completed": false,
      "is_claimed": false,
      "can_claim": false
    }
  ]
}
```

### Mission Types

- `daily`: Resets every day at midnight
- `weekly`: Resets every Monday
- `once`: One-time achievements

### Mission States

- **In Progress**: `progress < target_count`
- **Complete**: `progress >= target_count && !is_claimed`
- **Can Claim**: `is_completed && !is_claimed`
- **Claimed**: `is_claimed`

---

**Last Updated**: 2026-04-26
**Status**: Ready for testing
**Priority**: High
