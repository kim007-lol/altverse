# AU Reader V2 - Setup Guide

## Prerequisites

### Backend Requirements
- PHP 8.2 or higher
- Composer
- MySQL/PostgreSQL or SQLite (for development)
- Redis (optional, for caching)

### Frontend Requirements
- Flutter SDK 3.11 or higher
- Dart SDK
- Android Studio / Xcode (for mobile development)
- Visual Studio (for Windows development)

### Cloud Services (Optional for Development)
- AWS S3 or Cloudflare R2 (for image storage)
- Firebase (for push notifications)

---

## Backend Setup

### 1. Install Dependencies

```bash
cd backend
composer install
```

### 2. Environment Configuration

Copy the example environment file:
```bash
cp .env.example .env
```

Edit `.env` and configure:

```env
APP_NAME="AU Reader"
APP_ENV=local
APP_DEBUG=true
APP_URL=http://localhost:8000

# Database (SQLite for development)
DB_CONNECTION=sqlite
# DB_DATABASE=/absolute/path/to/database.sqlite

# Or use MySQL/PostgreSQL
# DB_CONNECTION=mysql
# DB_HOST=127.0.0.1
# DB_PORT=3306
# DB_DATABASE=au_reader
# DB_USERNAME=root
# DB_PASSWORD=

# Redis (optional)
REDIS_HOST=127.0.0.1
REDIS_PASSWORD=null
REDIS_PORT=6379

# S3/R2 Storage (optional for development)
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AWS_DEFAULT_REGION=auto
AWS_BUCKET=
AWS_ENDPOINT=
AWS_URL=

# Mail (optional)
MAIL_MAILER=log
```

### 3. Generate Application Key

```bash
php artisan key:generate
```

### 4. Create Database

For SQLite:
```bash
touch database/database.sqlite
```

For MySQL/PostgreSQL, create the database manually.

### 5. Run Migrations

```bash
php artisan migrate
```

### 6. Seed Database

```bash
php artisan db:seed
```

This will create:
- Genres
- Supporter levels
- Badges
- Missions
- First season
- Demo users (optional)

### 7. Create Storage Link

```bash
php artisan storage:link
```

### 8. Start Development Server

```bash
php artisan serve
```

Backend will be available at `http://localhost:8000`

### 9. Test API

Test the health endpoint:
```bash
curl http://localhost:8000/api/v1/public/genres
```

---

## Frontend Setup

### 1. Install Dependencies

```bash
cd frontend
flutter pub get
```

### 2. Configure API Endpoint

Edit `lib/core/constants/api_endpoints.dart`:

```dart
class ApiEndpoints {
  // Development
  static const String baseUrl = 'http://localhost:8000/api/v1';
  
  // Production
  // static const String baseUrl = 'https://your-domain.com/api/v1';
  
  // ... rest of endpoints
}
```

For Android emulator, use `http://10.0.2.2:8000/api/v1`
For iOS simulator, use `http://localhost:8000/api/v1`
For physical device, use your computer's IP address

### 3. Run Flutter Doctor

```bash
flutter doctor
```

Fix any issues reported.

### 4. Run the App

For Windows:
```bash
flutter run -d windows
```

For Android:
```bash
flutter run -d android
```

For iOS:
```bash
flutter run -d ios
```

---

## Development Workflow

### Backend Development

#### Run Tests
```bash
php artisan test
```

#### Clear Cache
```bash
php artisan cache:clear
php artisan config:clear
php artisan route:clear
```

#### Run Queue Worker (for jobs)
```bash
php artisan queue:work
```

#### Run Scheduler (for cron jobs)
```bash
php artisan schedule:work
```

### Frontend Development

#### Hot Reload
Flutter supports hot reload. Press `r` in terminal or save file in IDE.

#### Build for Production

Windows:
```bash
flutter build windows
```

Android:
```bash
flutter build apk --release
# or
flutter build appbundle --release
```

iOS:
```bash
flutter build ios --release
```

---

## Testing the Application

### 1. Create Test User

Via API:
```bash
curl -X POST http://localhost:8000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test User",
    "email": "test@example.com",
    "password": "password123",
    "password_confirmation": "password123"
  }'
```

### 2. Login

```bash
curl -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }'
```

Save the token from response.

### 3. Test Authenticated Endpoint

```bash
curl http://localhost:8000/api/v1/auth/me \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

---

## Common Issues & Solutions

### Backend Issues

#### Issue: "Class not found"
Solution:
```bash
composer dump-autoload
```

#### Issue: "Permission denied" on storage
Solution:
```bash
chmod -R 775 storage bootstrap/cache
```

#### Issue: Database connection error
Solution: Check `.env` database configuration and ensure database exists.

### Frontend Issues

#### Issue: "Pub get failed"
Solution:
```bash
flutter clean
flutter pub get
```

#### Issue: "No devices found"
Solution: Ensure emulator/simulator is running or device is connected.

#### Issue: "Network error" when calling API
Solution: Check API endpoint URL and ensure backend is running.

---

## Next Steps

After setup is complete:

1. ✅ Test user registration and login
2. ✅ Test role switching (reader ↔ author)
3. ✅ Create a test series (as author)
4. ✅ Upload test episodes
5. ✅ Test reading flow (as reader)
6. ✅ Test gamification (missions, XP, badges)
7. ✅ Test wallet and transactions
8. ✅ Test leaderboard

Refer to `DEVELOPMENT_ROADMAP.md` for feature development priorities.

---

## Production Deployment

### Backend Deployment

1. Set `APP_ENV=production` and `APP_DEBUG=false`
2. Configure production database
3. Set up Redis for caching
4. Configure S3/R2 for image storage
5. Set up queue worker as systemd service
6. Set up cron for scheduler
7. Configure web server (Nginx/Apache)
8. Enable HTTPS
9. Set up monitoring (Sentry, New Relic)

### Frontend Deployment

1. Update API endpoint to production URL
2. Build release version
3. Sign app (Android/iOS)
4. Upload to Play Store / App Store
5. Set up analytics
6. Configure push notifications

---

**Last Updated**: 2026-04-24
