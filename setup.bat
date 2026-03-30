@echo off
echo.
echo 🚀 Liya - Setup ^& Build Script
echo ================================
echo.

REM Check if Flutter is installed
where flutter >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Flutter is not installed!
    echo.
    echo 📥 Install Flutter:
    echo    Visit: https://docs.flutter.dev/get-started/install
    echo.
    pause
    exit /b 1
)

echo ✅ Flutter found
flutter --version
echo.

REM Install dependencies
echo 📦 Installing dependencies...
flutter pub get

if %ERRORLEVEL% NEQ 0 (
    echo ❌ Failed to install dependencies
    pause
    exit /b 1
)

echo.
echo ✅ Dependencies installed
echo.

REM Firebase setup instructions
echo 🔥 Firebase Setup
echo ================================
echo.
echo Before building, you need to configure Firebase:
echo.
echo 1. Create a Firebase project at https://console.firebase.google.com
echo 2. Enable Authentication (Email/Password)
echo 3. Enable Firestore Database
echo 4. Run: dart pub global activate flutterfire_cli
echo 5. Run: flutterfire configure
echo.
echo This will generate firebase_options.dart with your config
echo.

set /p FIREBASE_DONE="Have you completed Firebase setup? (y/n): "
if /i not "%FIREBASE_DONE%"=="y" (
    echo ⚠️  Please complete Firebase setup first
    pause
    exit /b 1
)

echo.
echo 🏗️  Building Liya...
echo ================================
echo.

REM Check available devices
echo 📱 Available devices:
flutter devices
echo.

set /p DEVICE_ID="Enter device ID (or press Enter for default): "

if "%DEVICE_ID%"=="" (
    echo 🚀 Running on default device...
    flutter run
) else (
    echo 🚀 Running on device: %DEVICE_ID%
    flutter run -d %DEVICE_ID%
)

pause
