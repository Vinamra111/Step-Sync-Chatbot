@echo off
REM Step Sync ChatBot - Setup and Test Script
REM This script installs dependencies, generates code, and runs tests

echo ========================================
echo Step Sync ChatBot - Setup and Test
echo ========================================
echo.

REM Check if Flutter is installed
where flutter >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Flutter is not installed or not in PATH!
    echo.
    echo Please install Flutter or add it to your PATH:
    echo 1. Download Flutter from https://flutter.dev
    echo 2. Add Flutter\bin to your System PATH
    echo 3. Run this script again
    echo.
    pause
    exit /b 1
)

echo [INFO] Flutter found:
flutter --version
echo.

REM Navigate to package directory
cd /d "%~dp0"
echo [INFO] Working directory: %CD%
echo.

REM Step 1: flutter pub get
echo ========================================
echo Step 1/3: Installing Dependencies
echo ========================================
echo Running: flutter pub get
echo.
flutter pub get
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERROR] Failed to install dependencies!
    pause
    exit /b 1
)
echo.
echo [SUCCESS] Dependencies installed!
echo.

REM Step 2: build_runner
echo ========================================
echo Step 2/3: Generating Code
echo ========================================
echo Running: flutter pub run build_runner build --delete-conflicting-outputs
echo.
echo This may take 10-30 seconds...
echo.
flutter pub run build_runner build --delete-conflicting-outputs
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERROR] Failed to generate code!
    pause
    exit /b 1
)
echo.
echo [SUCCESS] Code generation complete!
echo.

REM Step 3: flutter test
echo ========================================
echo Step 3/3: Running Tests
echo ========================================
echo Running: flutter test
echo.
echo This may take 30-60 seconds...
echo.
flutter test
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERROR] Tests failed!
    echo Please review the test output above.
    pause
    exit /b 1
)
echo.
echo [SUCCESS] All tests passed!
echo.

REM Summary
echo ========================================
echo Setup Complete!
echo ========================================
echo.
echo All steps completed successfully:
echo   [x] Dependencies installed
echo   [x] Code generated
echo   [x] Tests passed
echo.
echo You can now:
echo   - Run the example app: flutter run (in example/ directory)
echo   - Open in IDE: VS Code or Android Studio
echo   - Integrate into your app
echo.
echo Phase 4 Implementation: COMPLETE
echo.
pause
