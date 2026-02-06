@echo off
REM Manual build if Flutter PATH is not set
echo ========================================
echo Manual Build Instructions
echo ========================================
echo.
echo It looks like Flutter is not in your PATH.
echo.
echo Please follow these steps:
echo.
echo 1. Open a NEW Command Prompt or PowerShell
echo.
echo 2. Navigate to this folder:
echo    cd C:\ChatBot_StepSync\step_sync_chatbot_mobile
echo.
echo 3. Run these commands:
echo    flutter build apk --debug
echo    adb install -r build\app\outputs\flutter-apk\app-debug.apk
echo.
echo OR add Flutter to your PATH and run BUILD_AND_INSTALL.bat again
echo.
pause
