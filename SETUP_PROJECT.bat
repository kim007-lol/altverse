@echo off
echo ========================================
echo   AU Reader V2 - Project Setup
echo ========================================
echo.

echo This script will setup your development environment
echo.
pause

echo.
echo [STEP 1/6] Checking PHP...
php --version
if %errorlevel% neq 0 (
    echo ERROR: PHP not found! Please install PHP 8.3+
    pause
    exit /b 1
)
echo ✓ PHP is installed
echo.

echo [STEP 2/6] Checking Composer...
composer --version
if %errorlevel% neq 0 (
    echo ERROR: Composer not found! Please install Composer
    pause
    exit /b 1
)
echo ✓ Composer is installed
echo.

echo [STEP 3/6] Checking Flutter...
flutter --version
if %errorlevel% neq 0 (
    echo ERROR: Flutter not found! Please install Flutter
    pause
    exit /b 1
)
echo ✓ Flutter is installed
echo.

echo [STEP 4/6] Installing Backend Dependencies...
cd backend
composer install --no-interaction
if %errorlevel% neq 0 (
    echo ERROR: Failed to install backend dependencies
    cd ..
    pause
    exit /b 1
)
echo ✓ Backend dependencies installed
cd ..
echo.

echo [STEP 5/6] Installing Frontend Dependencies...
cd frontend
flutter pub get
if %errorlevel% neq 0 (
    echo ERROR: Failed to install frontend dependencies
    cd ..
    pause
    exit /b 1
)
echo ✓ Frontend dependencies installed
cd ..
echo.

echo [STEP 6/6] Checking Database...
cd backend
php artisan migrate:status
if %errorlevel% neq 0 (
    echo WARNING: Database not configured or migrations not run
    echo Please configure your .env file and run: php artisan migrate
)
cd ..
echo.

echo ========================================
echo   Setup Complete!
echo ========================================
echo.
echo Next steps:
echo   1. Configure backend/.env file (database, storage, etc)
echo   2. Run migrations: cd backend ^&^& php artisan migrate
echo   3. Seed database: cd backend ^&^& php artisan db:seed
echo   4. Start backend: START_BACKEND.bat
echo   5. Start frontend: START_FRONTEND.bat
echo.
echo For more information, see README.md
echo.
pause
