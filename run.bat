@echo off
REM Step Sync ChatBot - Master Script
REM Provides easy access to all common operations

:menu
cls
echo ========================================
echo Step Sync ChatBot - Master Menu
echo ========================================
echo.
echo What would you like to do?
echo.
echo 1. Full Setup (Install + Generate + Test)
echo 2. Quick Test (Run all tests)
echo 3. Test Phase 4 Only (Diagnostic tests)
echo 4. Run Example App
echo 5. Install Dependencies Only
echo 6. Generate Code Only
echo 7. Clean and Rebuild (Fix build issues)
echo 8. Open in VS Code
echo 9. Open Project Folder
echo 0. Exit
echo.
set /p choice="Enter your choice (0-9): "

if "%choice%"=="1" goto fullsetup
if "%choice%"=="2" goto quicktest
if "%choice%"=="3" goto phase4test
if "%choice%"=="4" goto runexample
if "%choice%"=="5" goto dependencies
if "%choice%"=="6" goto generate
if "%choice%"=="7" goto cleanrebuild
if "%choice%"=="8" goto vscode
if "%choice%"=="9" goto openfolder
if "%choice%"=="0" goto exit
echo Invalid choice!
pause
goto menu

:fullsetup
echo.
echo Running full setup...
echo.
cd packages\step_sync_chatbot
call setup_and_test.bat
pause
goto menu

:quicktest
echo.
echo Running quick test...
echo.
cd packages\step_sync_chatbot
call quick_test.bat
pause
goto menu

:phase4test
echo.
echo Running Phase 4 tests...
echo.
cd packages\step_sync_chatbot
call test_phase4.bat
pause
goto menu

:runexample
echo.
echo Running example app...
echo.
cd packages\step_sync_chatbot\example
call run_example.bat
pause
goto menu

:dependencies
echo.
echo Installing dependencies...
echo.
cd packages\step_sync_chatbot
flutter pub get
echo.
echo Done!
pause
goto menu

:generate
echo.
echo Generating code...
echo.
cd packages\step_sync_chatbot
flutter pub run build_runner build --delete-conflicting-outputs
echo.
echo Done!
pause
goto menu

:cleanrebuild
echo.
echo Running clean and rebuild...
echo.
cd packages\step_sync_chatbot
call clean_and_rebuild.bat
pause
goto menu

:vscode
echo.
echo Opening in VS Code...
code packages\step_sync_chatbot
goto menu

:openfolder
echo.
echo Opening project folder...
explorer packages\step_sync_chatbot
goto menu

:exit
echo.
echo Goodbye!
exit
