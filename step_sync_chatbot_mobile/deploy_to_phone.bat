@echo off
REM Deploy Step Sync ChatBot to Connected Phone
REM Created for quick testing of changes

echo ========================================
echo Step Sync ChatBot - Deploy to Phone
echo ========================================
echo.

REM Check if device is connected
echo Checking for connected device...
adb devices
echo.

REM Check if Flutter is available
where flutter >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Flutter not found in PATH!
    echo Please add Flutter to your PATH or run this from Flutter SDK directory
    pause
    exit /b 1
)

echo Device connected! Building and deploying...
echo.

REM Run the app in debug mode (faster build)
echo Building and installing app...
flutter run --debug

echo.
echo Done! App should be running on your phone.
pause
