@echo off
REM Build APK with new changes and install to phone
echo ========================================
echo Building APK with your changes...
echo ========================================
echo.

REM Build the debug APK
echo [1/3] Building APK (this takes 2-3 minutes)...
call flutter build apk --debug

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ERROR: Build failed!
    pause
    exit /b 1
)

echo.
echo [2/3] APK built successfully!
echo Location: build\app\outputs\flutter-apk\app-debug.apk
echo.

REM Install to connected phone
echo [3/3] Installing to phone (0011664AT000227)...
adb install -r build\app\outputs\flutter-apk\app-debug.apk

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ERROR: Installation failed!
    echo Make sure your phone is connected and USB debugging is enabled.
    pause
    exit /b 1
)

echo.
echo ========================================
echo SUCCESS! App installed on your phone.
echo ========================================
echo.
echo You can now:
echo 1. Open the app on your phone
echo 2. Test the new greeting with diagnostics
echo.
echo The app should now show issues immediately in the greeting!
echo.
pause
