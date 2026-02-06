@echo off
REM Run Step Sync ChatBot Example App

echo ========================================
echo Step Sync ChatBot - Example App
echo ========================================
echo.

REM Check if Flutter is installed
where flutter >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Flutter is not installed or not in PATH!
    pause
    exit /b 1
)

REM Navigate to example directory
cd /d "%~dp0"
echo [INFO] Working directory: %CD%
echo.

REM Check for connected devices
echo Checking for connected devices...
flutter devices
echo.

REM Ask user which device to run on
echo.
echo Options:
echo   1. Run on Chrome (web)
echo   2. Run on Windows (desktop)
echo   3. Run on connected Android device/emulator
echo   4. Run on connected iOS device/simulator
echo   5. Let Flutter choose
echo.
set /p choice="Enter your choice (1-5): "

if "%choice%"=="1" (
    echo.
    echo Running on Chrome...
    flutter run -d chrome
) else if "%choice%"=="2" (
    echo.
    echo Running on Windows...
    flutter run -d windows
) else if "%choice%"=="3" (
    echo.
    echo Running on Android...
    flutter run -d android
) else if "%choice%"=="4" (
    echo.
    echo Running on iOS...
    flutter run -d ios
) else if "%choice%"=="5" (
    echo.
    echo Running on default device...
    flutter run
) else (
    echo.
    echo Invalid choice! Running on default device...
    flutter run
)

pause
