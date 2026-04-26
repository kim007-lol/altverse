@echo off
echo ========================================
echo   AU Reader V2 - Starting Frontend
echo ========================================
echo.

cd frontend

echo [1/2] Checking Flutter version...
flutter --version
echo.

echo [2/2] Starting Flutter app...
echo Choose your platform:
echo   1. Chrome (Web)
echo   2. Windows Desktop
echo   3. Android Emulator
echo.
set /p choice="Enter your choice (1-3): "

if "%choice%"=="1" (
    echo Starting on Chrome...
    flutter run -d chrome
) else if "%choice%"=="2" (
    echo Starting on Windows...
    flutter run -d windows
) else if "%choice%"=="3" (
    echo Starting on Android...
    flutter run
) else (
    echo Invalid choice. Starting on Chrome by default...
    flutter run -d chrome
)

pause
