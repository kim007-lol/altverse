@echo off
echo ========================================
echo   AU Reader V2 - Running Tests
echo ========================================
echo.

echo Choose test suite:
echo   1. Backend API Tests
echo   2. Frontend Widget Tests
echo   3. All Tests
echo.
set /p choice="Enter your choice (1-3): "

if "%choice%"=="1" (
    echo.
    echo Running Backend API Tests...
    cd backend
    php artisan test
    cd ..
) else if "%choice%"=="2" (
    echo.
    echo Running Frontend Widget Tests...
    cd frontend
    flutter test
    cd ..
) else if "%choice%"=="3" (
    echo.
    echo Running Backend API Tests...
    cd backend
    php artisan test
    cd ..
    echo.
    echo Running Frontend Widget Tests...
    cd frontend
    flutter test
    cd ..
) else (
    echo Invalid choice!
)

echo.
pause
