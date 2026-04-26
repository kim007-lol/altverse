@echo off
echo ========================================
echo   AU Reader V2 - Starting Backend
echo ========================================
echo.

cd backend

echo [1/3] Checking PHP version...
php --version
echo.

echo [2/3] Checking database connection...
php artisan migrate:status
echo.

echo [3/3] Starting Laravel development server...
echo Backend will be available at: http://localhost:8000
echo Press Ctrl+C to stop the server
echo.

php artisan serve

pause
