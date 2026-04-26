# AU Reader V2

A modern webtoon/comic reading platform with gamification features, built with Laravel 12 and Flutter.

## 🚀 Features

### Reader Features
- Browse and discover series (FYP algorithm)
- Read episodes with smooth page navigation
- Bookmark and collect favorite series
- Follow authors
- Comment and like episodes
- Mission system with XP and rewards
- Daily login rewards
- Leaderboard (XP, Supporters, Authors)
- Episode unlock with coins
- Search with filters and history

### Author Features
- Create and manage series
- Upload episodes with page editor
- Analytics dashboard (views, engagement, retention)
- Earnings tracking
- Author tier progression
- Follower management
- CSV export for analytics

### Gamification
- 18 Missions (4 daily, 5 weekly, 9 one-time)
- 25 Badges (reader, author, follower, spend-based)
- XP and Level system
- Season-based leaderboards
- Coin economy
- Tip system

## 📋 Requirements

### Backend
- PHP 8.3+
- Composer 2.x
- PostgreSQL 14+ (or MySQL 8+)
- Redis (optional, for caching)
- Node.js 18+ (for asset compilation)

### Frontend
- Flutter 3.41+
- Dart 3.11+
- Android Studio / VS Code
- Chrome (for web development)

### PHP Extensions Required
- PDO
- pdo_pgsql (or pdo_mysql)
- mbstring
- openssl
- tokenizer
- xml
- ctype
- json
- bcmath
- fileinfo

## 🛠️ Installation

### Quick Setup (Windows)

1. **Run Setup Script**
   ```bash
   SETUP_PROJECT.bat
   ```

2. **Configure Environment**
   - Copy `backend/.env.example` to `backend/.env`
   - Update database credentials
   - Update storage credentials (R2/S3)

3. **Run Migrations**
   ```bash
   cd backend
   php artisan migrate
   php artisan db:seed
   ```

4. **Start Backend**
   ```bash
   START_BACKEND.bat
   ```
   Backend will be available at: http://localhost:8000

5. **Start Frontend**
   ```bash
   START_FRONTEND.bat
   ```
   Choose your platform (Chrome/Windows/Android)

### Manual Setup

#### Backend Setup

```bash
# Install dependencies
cd backend
composer install

# Configure environment
cp .env.example .env
php artisan key:generate

# Setup database
php artisan migrate
php artisan db:seed

# Start server
php artisan serve
```

#### Frontend Setup

```bash
# Install dependencies
cd frontend
flutter pub get

# Run on Chrome
flutter run -d chrome

# Run on Windows
flutter run -d windows

# Run on Android
flutter run
```

## 📁 Project Structure

```
AU_Reader_V2/
├── backend/                    # Laravel 12 Backend
│   ├── app/
│   │   ├── Console/           # Artisan commands
│   │   ├── Events/            # Event classes
│   │   ├── Http/
│   │   │   ├── Controllers/   # API controllers
│   │   │   ├── Middleware/    # Custom middleware
│   │   │   ├── Requests/      # Form requests (validation)
│   │   │   └── Responses/     # API response helpers
│   │   ├── Jobs/              # Queue jobs
│   │   ├── Models/            # Eloquent models
│   │   ├── Providers/         # Service providers
│   │   └── Services/          # Business logic services
│   ├── config/                # Configuration files
│   ├── database/
│   │   ├── migrations/        # Database migrations
│   │   └── seeders/           # Database seeders
│   ├── routes/
│   │   └── api.php           # API routes
│   └── storage/              # File storage
│
├── frontend/                  # Flutter Frontend
│   ├── lib/
│   │   ├── core/
│   │   │   ├── constants/    # API endpoints, constants
│   │   │   ├── routing/      # App routing
│   │   │   ├── services/     # API service, auth service
│   │   │   └── theme/        # App theme (clean design)
│   │   ├── features/
│   │   │   ├── auth/         # Authentication screens
│   │   │   ├── reader/       # Reader features
│   │   │   ├── author/       # Author features
│   │   │   ├── gamification/ # Missions, badges, leaderboard
│   │   │   └── shared/       # Shared features
│   │   └── shared/
│   │       └── widgets/      # Reusable widgets
│   └── pubspec.yaml          # Flutter dependencies
│
├── SETUP_PROJECT.bat          # Setup script
├── START_BACKEND.bat          # Start backend server
├── START_FRONTEND.bat         # Start frontend app
├── RUN_TESTS.bat             # Run tests
└── README.md                 # This file
```

## 🎨 Design System

### Clean Design Principles
- ✅ No emoji
- ✅ No weird icons (only clean outline icons)
- ✅ No weird fonts (system fonts with proper weights)
- ✅ Clean color palette (black, gray, blue)
- ✅ Subtle borders (1px)
- ✅ Consistent spacing
- ✅ Clear typography hierarchy
- ✅ Professional and minimal

### Color Palette
- Primary: `#1A1A1A` (Deep Black)
- Secondary: `#6B6B6B` (Medium Gray)
- Accent: `#2196F3` (Clean Blue)
- Background: `#FAFAFA` (Off-white)
- Surface: `#FFFFFF` (Pure White)
- Error: `#E53935` (Clean Red)
- Success: `#43A047` (Clean Green)

## 🔌 API Documentation

### Base URL
```
http://localhost:8000/api/v1
```

### Authentication
All authenticated endpoints require Bearer token:
```
Authorization: Bearer {token}
```

### Key Endpoints

#### Authentication
- `POST /auth/register` - Register new user
- `POST /auth/login` - Login
- `POST /auth/logout` - Logout
- `GET /auth/me` - Get current user
- `PUT /auth/profile` - Update profile
- `POST /auth/switch-role` - Switch between reader/author

#### Reader
- `GET /reader/fyp` - For You Page
- `GET /reader/search` - Search series
- `GET /reader/series/{id}` - Series detail
- `GET /reader/series/{seriesId}/episodes/{episodeId}` - Read episode
- `POST /reader/bookmarks/{seriesId}/toggle` - Toggle bookmark
- `POST /reader/follow/{userId}/toggle` - Toggle follow

#### Author
- `GET /author/dashboard` - Author dashboard
- `GET /author/series` - List my series
- `POST /author/series` - Create series
- `POST /author/series/{seriesId}/episodes` - Create episode
- `POST /author/episodes/{episodeId}/publish` - Publish episode
- `GET /author/analytics/overview` - Analytics overview

#### Gamification
- `GET /missions` - List missions
- `POST /missions/{missionId}/claim` - Claim mission reward
- `GET /wallet/badges` - List badges
- `GET /leaderboard/overview` - Leaderboard overview

For complete API documentation, see `API_DOCUMENTATION.md`

## 🧪 Testing

### Backend Tests
```bash
cd backend
php artisan test
```

### Frontend Tests
```bash
cd frontend
flutter test
```

### Run All Tests
```bash
RUN_TESTS.bat
```

## 📊 Database

### Migrations
```bash
cd backend
php artisan migrate
```

### Seeders
```bash
php artisan db:seed
```

### Reset Database
```bash
php artisan migrate:fresh --seed
```

## 🔧 Configuration

### Backend Configuration

Edit `backend/.env`:

```env
# App
APP_NAME="AU Reader"
APP_URL=http://localhost:8000

# Database
DB_CONNECTION=pgsql
DB_HOST=127.0.0.1
DB_PORT=5432
DB_DATABASE=au_reader
DB_USERNAME=postgres
DB_PASSWORD=your_password

# Storage (R2/S3)
AWS_ACCESS_KEY_ID=your_access_key
AWS_SECRET_ACCESS_KEY=your_secret_key
AWS_BUCKET=your_bucket
AWS_URL=your_public_url
AWS_ENDPOINT=your_endpoint
```

### Frontend Configuration

Edit `frontend/lib/core/constants/api_constants.dart`:

```dart
static const String baseUrl = 'http://localhost:8000/api/v1';
```

## 📈 Performance

### Backend Optimizations
- 40+ composite database indexes
- Query optimization with eager loading
- Caching for leaderboards (5min TTL)
- Atomic transactions for financial operations
- Row-level locking for race condition prevention

### Frontend Optimizations
- Cached network images
- Lazy loading for lists
- Pagination for all data
- Optimized image compression
- Efficient state management

## 🚀 Deployment

### Backend Deployment
1. Set `APP_ENV=production` in `.env`
2. Set `APP_DEBUG=false`
3. Run `php artisan config:cache`
4. Run `php artisan route:cache`
5. Run `php artisan view:cache`
6. Setup queue worker: `php artisan queue:work`
7. Setup scheduler: Add to cron `* * * * * php artisan schedule:run`

### Frontend Deployment

#### Web
```bash
flutter build web
```

#### Android
```bash
flutter build apk --release
```

#### Windows
```bash
flutter build windows --release
```

## 📝 Development Notes

### Backend
- Laravel 12 with PHP 8.3
- PostgreSQL for database
- Sanctum for authentication
- Redis for caching (optional)
- R2/S3 for file storage

### Frontend
- Flutter 3.41 with Dart 3.11
- Provider for state management
- go_router for navigation
- http for API calls
- cached_network_image for images

## 🐛 Troubleshooting

### Backend Issues

**Database connection error**
- Check database credentials in `.env`
- Ensure PostgreSQL is running
- Run `php artisan migrate:status`

**Storage error**
- Check R2/S3 credentials in `.env`
- Verify bucket permissions
- Test with `php artisan storage:link`

### Frontend Issues

**API connection error**
- Check backend is running on http://localhost:8000
- Verify API base URL in `api_constants.dart`
- Check CORS configuration in backend

**Build error**
- Run `flutter clean`
- Run `flutter pub get`
- Check Flutter version: `flutter --version`

## 📚 Additional Resources

- [Laravel Documentation](https://laravel.com/docs)
- [Flutter Documentation](https://flutter.dev/docs)
- [API Test Guide](API_TEST_GUIDE.md)
- [Complete API Test Report](COMPLETE_API_TEST_REPORT.md)
- [Development Roadmap](DEVELOPMENT_ROADMAP.md)

## 👥 Team

- Backend: Laravel 12 + PostgreSQL
- Frontend: Flutter 3.41
- Design: Clean & Minimal

## 📄 License

Private Project - All Rights Reserved

---

**Last Updated**: 2026-04-25

For questions or issues, please check the documentation files or create an issue.
